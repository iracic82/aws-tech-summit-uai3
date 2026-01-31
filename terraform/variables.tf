variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"
}

variable "vpcs" {
  description = "Map of VPC configurations to deploy"
  type = map(object({
    vpc_cidr      = string
    subnet_cidr   = string
    instance_name = string
    instance_type = string
    private_ip    = string
    user_data     = string
  }))
}

variable "dns_domain" {
  description = "Private DNS domain for Route53 hosted zone"
  type        = string
  default     = "raj-demo.internal"
}

variable "dns_records" {
  description = "Map of DNS A records to create in the private zone"
  type = map(object({
    subdomain = string
    vpc_key   = string
  }))
  default = {}
}
