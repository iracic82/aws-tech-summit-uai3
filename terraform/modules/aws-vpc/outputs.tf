# --- Networking ---

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_subnet.this.id
}

output "route_table_id" {
  description = "Route table ID (for TGW/peering route injection)"
  value       = aws_route_table.this.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.this.id
}

# --- Compute ---

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "EC2 Elastic IP (public)"
  value       = aws_eip.this.public_ip
}

output "private_ip" {
  description = "EC2 private IP"
  value       = var.private_ip
}

output "key_pair_name" {
  description = "SSH key pair name"
  value       = aws_key_pair.this.key_name
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -o StrictHostKeyChecking=no -i ${var.aws_ec2_key_pair_name}.pem ec2-user@${aws_eip.this.public_ip}"
}
