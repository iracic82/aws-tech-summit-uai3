variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
}

variable "aws_vpc_name" {
  description = "Name tag for the VPC"
  type        = string
}

variable "aws_vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "aws_subnet_name" {
  description = "Name tag for the subnet"
  type        = string
}

variable "aws_subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
}

variable "igw_name" {
  description = "Name tag for the Internet Gateway"
  type        = string
}

variable "rt_name" {
  description = "Name tag for the Route Table"
  type        = string
}

variable "aws_ec2_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "aws_ec2_key_pair_name" {
  description = "Name for the SSH key pair"
  type        = string
}

variable "aws_ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "private_ip" {
  description = "Static private IP for the EC2 instance ENI"
  type        = string
}

variable "internet" {
  description = "Whether to create IGW and default route (true/false as string for PoC compat)"
  type        = string
  default     = "true"
}

variable "tgw" {
  description = "Whether to create a Transit Gateway (true/false as string for PoC compat)"
  type        = string
  default     = "false"
}

variable "user_data" {
  description = "User data script for EC2 instance bootstrap"
  type        = string
  default     = ""
}

variable "resource_owner" {
  description = "ResourceOwner tag value for all resources"
  type        = string
  default     = "iracic@infoblox.com"
}
