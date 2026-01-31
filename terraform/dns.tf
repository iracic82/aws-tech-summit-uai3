# --- Route53 Private Hosted Zone ---

resource "aws_route53_zone" "private_zone" {
  name    = var.route53_domain_name
  comment = "Private hosted zone for Raj Demo"

  dynamic "vpc" {
    for_each = { for key, data in module.aws_instances_eu_central : key => data.aws_vpc_id }
    content {
      vpc_id     = vpc.value
      vpc_region = var.aws_region
    }
  }

  tags = {
    "Name"          = "${var.route53_domain_name}-private-zone"
    "ResourceOwner" = var.resource_owner
  }
}

# --- DNS A Records (derived from VPC app_fqdn) ---

resource "aws_route53_record" "dns_records" {
  count   = var.enable_dns_records ? length(keys(var.EU_Central_FrontEnd)) : 0
  zone_id = aws_route53_zone.private_zone.id

  name = lookup(
    var.EU_Central_FrontEnd[element(keys(var.EU_Central_FrontEnd), count.index)],
    "app_fqdn",
    "default.${var.route53_domain_name}"
  )
  type = "A"
  ttl  = 300

  records = [
    lookup(
      var.EU_Central_FrontEnd[element(keys(var.EU_Central_FrontEnd), count.index)],
      "private_ip",
      "10.0.0.1"
    )
  ]
}
