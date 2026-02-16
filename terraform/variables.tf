variable "aws_region" {
  description = "AWS default region for resource deployment"
  type        = string
  default     = "eu-central-1"
}

variable "resource_owner" {
  description = "ResourceOwner tag applied to all resources via default_tags"
  type        = string
  default     = "iracic@infoblox.com"
}

# --- VPC Scaling ---

variable "vpcs_per_region" {
  description = "Number of VPCs to deploy per region"
  type        = number
  default     = 4
}

# --- DNS ---

variable "route53_domain_name" {
  description = "Private hosted zone domain name"
  type        = string
  default     = "uai3.internal"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]+[a-z]$", var.route53_domain_name))
    error_message = "route53_domain_name must be a valid domain (e.g. uai3.internal)."
  }
}

variable "enable_dns_records" {
  description = "Whether to create Route53 DNS A records from VPC app_fqdn"
  type        = bool
  default     = true
}

# --- Participant ---

variable "participant_id" {
  description = "Unique participant ID (from INSTRUQT_PARTICIPANT_ID) — used to isolate resources per user"
  type        = string
  default     = "local"
}

# --- S3 ---

variable "enable_s3_bucket" {
  description = "Whether to create the S3 bucket and related resources"
  type        = bool
  default     = false
}

variable "s3_bucket_prefix" {
  description = "Prefix for the S3 bucket name (participant_id is appended for uniqueness)"
  type        = string
  default     = "uai3"
}
