output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "ec2_public_ip" {
  description = "Public (Elastic) IP of the EC2 instance"
  value       = aws_eip.this.public_ip
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = var.private_ip
}

output "ssh_command" {
  description = "SSH command to access the EC2 instance"
  value       = "ssh -o StrictHostKeyChecking=no -i ${var.vpc_name}-key.pem ec2-user@${aws_eip.this.public_ip}"
}

output "key_pair_name" {
  description = "Name of the SSH key pair"
  value       = aws_key_pair.this.key_name
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.main.id
}
