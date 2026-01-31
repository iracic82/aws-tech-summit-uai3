aws_region     = "eu-central-1"
resource_owner = "iracic@infoblox.com"

# --- DNS ---

route53_domain_name = "uai3.internal"
enable_dns_records  = true

# --- S3 (disabled by default — set true to create) ---
# Bucket name = "${s3_bucket_prefix}-${participant_id}" (unique per participant)

enable_s3_bucket  = false
s3_bucket_prefix  = "uai3"

# --- VPC Definitions ---
# Add/remove entries to scale. Each entry creates:
#   VPC → Subnet → IGW → RT → SG → ENI → EC2 → EIP → Key Pair
#   + Route53 A record from app_fqdn → private_ip

EU_Central_FrontEnd = {
  VPC1 = {
    aws_vpc_name          = "UAI3-Vpc1"
    igw_name              = "UAI3-Vpc1-IGW"
    rt_name               = "UAI3-Vpc1-RT"
    aws_subnet_name       = "UAI3-Vpc1-Subnet"
    private_ip            = "10.10.1.10"
    app_fqdn              = "app1.uai3.internal"
    aws_ec2_name          = "UAI3-Web1"
    aws_ec2_key_pair_name = "UAI3_EU_Central_1"
    aws_vpc_cidr          = "10.10.0.0/16"
    aws_subnet_cidr       = "10.10.1.0/24"
  }
  VPC2 = {
    aws_vpc_name          = "UAI3-Vpc2"
    igw_name              = "UAI3-Vpc2-IGW"
    rt_name               = "UAI3-Vpc2-RT"
    aws_subnet_name       = "UAI3-Vpc2-Subnet"
    private_ip            = "10.20.1.10"
    app_fqdn              = "app2.uai3.internal"
    aws_ec2_name          = "UAI3-Web2"
    aws_ec2_key_pair_name = "UAI3_EU_Central_2"
    aws_vpc_cidr          = "10.20.0.0/16"
    aws_subnet_cidr       = "10.20.1.0/24"
  }
}
