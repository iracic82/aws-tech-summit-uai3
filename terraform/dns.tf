# --- Route53 Private Hosted Zone ---

resource "aws_route53_zone" "private" {
  name    = var.route53_domain_name
  comment = "Private hosted zone for Raj Demo"

  dynamic "vpc" {
    for_each = local.all_vpc_associations
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.region
    }
  }

  tags = { Name = "${var.route53_domain_name}-zone" }
}

# --- DNS A Records (derived from all_vpcs across all regions) ---

locals {
  dns_records = var.enable_dns_records ? merge([
    for region, vpcs in local.all_vpcs : {
      for key, vpc in vpcs : "${region}/${key}" => {
        fqdn       = vpc.app_fqdn
        private_ip = vpc.private_ip
      }
    }
  ]...) : {}
}

resource "aws_route53_record" "app" {
  for_each = local.dns_records

  zone_id = aws_route53_zone.private.zone_id
  name    = each.value.fqdn
  type    = "A"
  ttl     = 300
  records = [each.value.private_ip]
}
