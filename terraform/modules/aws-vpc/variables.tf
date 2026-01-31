variable "vpc_name" {
  description = "Name tag for the VPC and related resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "private_ip" {
  description = "Static private IP for the EC2 instance ENI"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Amazon Linux 2023)"
  type        = string
}

variable "user_data" {
  description = "User data script for EC2 instance"
  type        = string
  default     = ""
}

variable "enable_internet" {
  description = "Whether to create IGW and public route table"
  type        = bool
  default     = true
}

variable "key_name_prefix" {
  description = "Prefix for the SSH key pair name"
  type        = string
  default     = "raj-demo"
}
