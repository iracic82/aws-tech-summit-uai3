# --- Route53 Private Hosted Zone ---

resource "aws_route53_zone" "private" {
  name    = var.route53_domain_name
  comment = "Private hosted zone for Raj Demo"

  dynamic "vpc" {
    for_each = module.aws_instances_eu_central
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = var.aws_region
    }
  }

  tags = { Name = "${var.route53_domain_name}-zone" }
}

# --- DNS A Records (derived from VPC app_fqdn via for_each) ---

locals {
  dns_records = var.enable_dns_records ? {
    for key, vpc in var.EU_Central_FrontEnd : key => {
      fqdn       = vpc.app_fqdn
      private_ip = vpc.private_ip
    }
  } : {}
}

resource "aws_route53_record" "app" {
  for_each = local.dns_records

  zone_id = aws_route53_zone.private.zone_id
  name    = each.value.fqdn
  type    = "A"
  ttl     = 300
  records = [each.value.private_ip]
}
