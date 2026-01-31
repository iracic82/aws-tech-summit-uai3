aws_region     = "eu-central-1"
resource_owner = "iracic@infoblox.com"

# --- DNS ---

route53_domain_name = "raj-demo.internal"
enable_dns_records  = true

# --- S3 (disabled by default — set true to create) ---

enable_s3_bucket = false
s3_bucket_name   = "raj-demo-infoblox"

# --- VPC Definitions ---
# Add/remove entries to scale. Each entry creates:
#   VPC → Subnet → IGW → RT → SG → ENI → EC2 → EIP → Key Pair
#   + Route53 A record from app_fqdn → private_ip

EU_Central_FrontEnd = {
  VPC1 = {
    aws_vpc_name          = "RajDemoVpc1"
    igw_name              = "RajDemoVpc1-IGW"
    rt_name               = "RajDemoVpc1-RT"
    aws_subnet_name       = "RajDemoVpc1-Subnet"
    private_ip            = "10.10.1.10"
    app_fqdn              = "app1.raj-demo.internal"
    aws_ec2_name          = "RajDemoWeb1"
    aws_ec2_key_pair_name = "EU_Central_RajDemo1"
    aws_vpc_cidr          = "10.10.0.0/16"
    aws_subnet_cidr       = "10.10.1.0/24"
  }
  VPC2 = {
    aws_vpc_name          = "RajDemoVpc2"
    igw_name              = "RajDemoVpc2-IGW"
    rt_name               = "RajDemoVpc2-RT"
    aws_subnet_name       = "RajDemoVpc2-Subnet"
    private_ip            = "10.20.1.10"
    app_fqdn              = "app2.raj-demo.internal"
    aws_ec2_name          = "RajDemoWeb2"
    aws_ec2_key_pair_name = "EU_Central_RajDemo2"
    aws_vpc_cidr          = "10.20.0.0/16"
    aws_subnet_cidr       = "10.20.1.0/24"
  }
}
