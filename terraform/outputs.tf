# --- VPC Outputs ---

output "vpc_ids" {
  description = "Map of VPC names to VPC IDs"
  value       = { for k, v in module.vpc : k => v.vpc_id }
}

# --- EC2 Public IPs ---

output "ec2_public_ips" {
  description = "Map of VPC names to EC2 public (Elastic) IPs"
  value       = { for k, v in module.vpc : k => v.ec2_public_ip }
}

# --- EC2 Private IPs ---

output "ec2_private_ips" {
  description = "Map of VPC names to EC2 private IPs"
  value       = { for k, v in module.vpc : k => v.ec2_private_ip }
}

# --- SSH Commands ---

output "ssh_commands" {
  description = "SSH commands to access each EC2 instance"
  value       = { for k, v in module.vpc : k => v.ssh_command }
}

# --- DNS Zone ---

output "dns_zone_id" {
  description = "Route53 private hosted zone ID"
  value       = aws_route53_zone.private.zone_id
}

output "dns_zone_name" {
  description = "Route53 private hosted zone name"
  value       = aws_route53_zone.private.name
}

# --- DNS Records ---

output "dns_records" {
  description = "Map of DNS record names to their values"
  value       = { for k, v in aws_route53_record.app : k => v.fqdn }
}
