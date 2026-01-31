# --- VPC Outputs ---

output "vpc_ids" {
  description = "Map of VPC keys to VPC IDs"
  value       = { for k, v in module.aws_instances_eu_central : k => v.aws_vpc_id }
}

output "vpc_names" {
  description = "Map of VPC keys to VPC names"
  value       = { for k, v in module.aws_instances_eu_central : k => v.aws_vpc_name }
}

output "vpc_cidrs" {
  description = "Map of VPC keys to VPC CIDRs"
  value       = { for k, v in module.aws_instances_eu_central : k => v.aws_vpc_cidr }
}

# --- Networking Outputs ---

output "subnet_ids" {
  description = "Map of VPC keys to subnet IDs"
  value       = { for k, v in module.aws_instances_eu_central : k => v.subnet_id }
}

output "route_table_ids" {
  description = "Map of VPC keys to route table IDs (for TGW route injection)"
  value       = { for k, v in module.aws_instances_eu_central : k => v.rt_id }
}

# --- EC2 Outputs ---

output "ec2_public_ips" {
  description = "Map of VPC keys to EC2 Elastic IPs"
  value       = { for k, v in module.aws_instances_eu_central : k => v.ec2_public_ip }
}

output "ec2_private_ips" {
  description = "Map of VPC keys to EC2 private IPs"
  value       = { for k, v in module.aws_instances_eu_central : k => v.ec2_private_ip }
}

output "ssh_commands" {
  description = "SSH commands to access each EC2 instance"
  value       = { for k, v in module.aws_instances_eu_central : k => v.ssh_command }
}

# --- DNS Outputs ---

output "dns_zone_id" {
  description = "Route53 private hosted zone ID"
  value       = aws_route53_zone.private_zone.zone_id
}

output "dns_zone_name" {
  description = "Route53 private hosted zone domain"
  value       = aws_route53_zone.private_zone.name
}

output "dns_records" {
  description = "DNS A records created"
  value       = [for r in aws_route53_record.dns_records : r.fqdn]
}

# --- S3 Outputs ---

output "s3_bucket_name" {
  description = "S3 bucket name (if created)"
  value       = var.enable_s3_bucket ? aws_s3_bucket.demo[0].bucket : null
}

output "s3_bucket_domain" {
  description = "S3 bucket regional domain name (if created)"
  value       = var.enable_s3_bucket ? aws_s3_bucket.demo[0].bucket_regional_domain_name : null
}
