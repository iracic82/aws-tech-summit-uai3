variable "aws_vpc_name" {
  description = "Name tag for the VPC"
  type        = string
}

variable "aws_vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.aws_vpc_cidr, 0))
    error_message = "aws_vpc_cidr must be a valid CIDR block (e.g. 10.10.0.0/16)."
  }
}

variable "aws_subnet_name" {
  description = "Name tag for the subnet"
  type        = string
}

variable "aws_subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string

  validation {
    condition     = can(cidrhost(var.aws_subnet_cidr, 0))
    error_message = "aws_subnet_cidr must be a valid CIDR block (e.g. 10.10.1.0/24)."
  }
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

variable "ami_id" {
  description = "AMI ID for the EC2 instance (resolved at root level)"
  type        = string
}

variable "private_ip" {
  description = "Static private IP for the EC2 instance ENI"
  type        = string

  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", var.private_ip))
    error_message = "private_ip must be a valid IPv4 address (e.g. 10.10.1.10)."
  }
}

variable "internet" {
  description = "Whether to create IGW and default route to the internet"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script for EC2 instance bootstrap"
  type        = string
  default     = ""
}
