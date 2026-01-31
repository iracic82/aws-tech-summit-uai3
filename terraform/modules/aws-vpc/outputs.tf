output "aws_vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.vpc1.id
}

output "aws_vpc_name" {
  description = "Name of the VPC"
  value       = var.aws_vpc_name
}

output "aws_vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = var.aws_vpc_cidr
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.subnet1.id
}

output "rt_id" {
  description = "ID of the route table (for TGW route injection)"
  value       = aws_route_table.rt_vpc1.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.sg_allow_access_inbound.id
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ec2_linux.id
}

output "ec2_public_ip" {
  description = "Elastic IP of the EC2 instance"
  value       = aws_eip.eip.public_ip
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = var.private_ip
}

output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.demo_key_pair.key_name
}

output "ssh_command" {
  description = "SSH command to access the EC2 instance"
  value       = "ssh -o StrictHostKeyChecking=no -i ${var.aws_ec2_key_pair_name}.pem ec2-user@${aws_eip.eip.public_ip}"
}

output "enable_peering" {
  description = "Passthrough for peering compatibility (always false for AWS VPCs)"
  value       = false
}
