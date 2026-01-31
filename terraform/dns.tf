# --- Route53 Private Hosted Zone ---

resource "aws_route53_zone" "private" {
  name = var.dns_domain

  # Associate with ALL VPCs created by the module
  dynamic "vpc" {
    for_each = module.vpc
    content {
      vpc_id = vpc.value.vpc_id
    }
  }

  tags = { Name = "${var.dns_domain}-private-zone" }
}

# --- DNS A Records ---

resource "aws_route53_record" "app" {
  for_each = var.dns_records

  zone_id = aws_route53_zone.private.zone_id
  name    = "${each.value.subdomain}.${var.dns_domain}"
  type    = "A"
  ttl     = 300
  records = [module.vpc[each.value.vpc_key].ec2_private_ip]
}
