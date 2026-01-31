variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "eu-central-1"
}

variable "resource_owner" {
  description = "ResourceOwner tag for all resources"
  type        = string
  default     = "iracic@infoblox.com"
}

# --- VPC Definitions (map-of-objects per region) ---

variable "EU_Central_FrontEnd" {
  description = "Map of VPC configurations for EU Central region"
  type = map(object({
    aws_vpc_name          = string
    igw_name              = string
    rt_name               = string
    aws_subnet_name       = string
    private_ip            = string
    app_fqdn              = string
    aws_ec2_name          = string
    aws_ec2_key_pair_name = string
    aws_vpc_cidr          = string
    aws_subnet_cidr       = string
  }))
  default = {}
}

# --- DNS ---

variable "route53_domain_name" {
  description = "Private hosted zone domain name"
  type        = string
  default     = "raj-demo.internal"
}

variable "enable_dns_records" {
  description = "Whether to create Route53 DNS A records from VPC app_fqdn"
  type        = bool
  default     = true
}

# --- S3 ---

variable "enable_s3_bucket" {
  description = "Whether to create the S3 bucket and related resources"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "Name for the S3 bucket"
  type        = string
  default     = "raj-demo-infoblox"
}
