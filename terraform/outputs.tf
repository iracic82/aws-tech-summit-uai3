# --- Networking ---

output "vpc_ids" {
  description = "region/VPC key → VPC ID"
  value       = { for k, v in local.all_modules : k => v.vpc_id }
}

output "vpc_cidrs" {
  description = "region/VPC key → CIDR block"
  value       = { for k, v in local.all_modules : k => v.vpc_cidr }
}

output "subnet_ids" {
  description = "region/VPC key → Subnet ID"
  value       = { for k, v in local.all_modules : k => v.subnet_id }
}

output "route_table_ids" {
  description = "region/VPC key → Route table ID (for TGW/peering route injection)"
  value       = { for k, v in local.all_modules : k => v.route_table_id }
}

# --- Compute ---

output "ec2_public_ips" {
  description = "region/VPC key → EC2 Elastic IP"
  value       = { for k, v in local.all_modules : k => v.public_ip }
}

output "ec2_private_ips" {
  description = "region/VPC key → EC2 private IP"
  value       = { for k, v in local.all_modules : k => v.private_ip }
}

output "ssh_commands" {
  description = "region/VPC key → SSH command"
  value       = { for k, v in local.all_modules : k => v.ssh_command }
}

# --- ALB ---

output "alb_dns_names" {
  description = "region/VPC key → ALB DNS name"
  value       = { for k, v in local.all_modules : k => v.alb_dns_name if v.alb_dns_name != null }
}

# --- DNS ---

output "dns_zone_id" {
  description = "Route53 private hosted zone ID"
  value       = aws_route53_zone.private.zone_id
}

output "dns_records" {
  description = "DNS record key → FQDN"
  value       = { for k, v in aws_route53_record.app : k => v.fqdn }
}

# --- S3 ---

output "s3_bucket_name" {
  description = "S3 bucket name (null if disabled)"
  value       = var.enable_s3_bucket ? aws_s3_bucket.this[0].bucket : null
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN (null if disabled)"
  value       = var.enable_s3_bucket ? aws_s3_bucket.this[0].arn : null
}
