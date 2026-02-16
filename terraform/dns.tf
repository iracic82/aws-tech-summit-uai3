# --- Route53 Private Hosted Zone ---
# Create with only the first VPC (eu-central-1/VPC1) — additional
# VPCs are associated via separate resources that run in parallel.

resource "aws_route53_zone" "private" {
  name    = var.route53_domain_name
  comment = "Private hosted zone for Raj Demo"

  vpc {
    vpc_id     = module.vpcs_eu_central_1["VPC1"].vpc_id
    vpc_region = "eu-central-1"
  }

  tags = { Name = "${var.route53_domain_name}-zone" }

  # Ignore vpc changes — additional VPCs managed by aws_route53_zone_association
  lifecycle {
    ignore_changes = [vpc]
  }
}

# --- Parallel VPC associations (all except the initial one) ---

locals {
  # Remove the VPC already inline in the zone resource
  extra_vpc_associations = {
    for k, v in local.all_vpc_associations : k => v
    if k != "eu-central-1/VPC1"
  }
}

resource "aws_route53_zone_association" "extra" {
  for_each = local.extra_vpc_associations

  zone_id    = aws_route53_zone.private.zone_id
  vpc_id     = each.value.vpc_id
  vpc_region = each.value.region
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
