aws_region     = "eu-central-1"
resource_owner = "iracic@infoblox.com"

# --- VPC Scaling ---
# 4 VPCs per region × 10 regions = 40 VPCs total

vpcs_per_region = 4

# --- DNS ---

route53_domain_name = "uai3.internal"
enable_dns_records  = true

# --- S3 (disabled by default — set true to create) ---
# Bucket name = "${s3_bucket_prefix}-${participant_id}" (unique per participant)

enable_s3_bucket = false
s3_bucket_prefix = "uai3"
