# AWS Tech Summit - Infoblox UAI3 Lab

Modular Terraform infrastructure for deploying multi-VPC environments with Docker web applications and Route53 private DNS.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Account                              │
│                                                                 │
│  ┌─────────────────────┐    ┌─────────────────────┐            │
│  │  VPC1 (10.10.0.0/16)│    │  VPC2 (10.20.0.0/16)│   + more  │
│  │  ┌───────────────┐  │    │  ┌───────────────┐  │            │
│  │  │ EC2 + Docker  │  │    │  │ EC2 + Docker  │  │            │
│  │  │ nginx:alpine  │  │    │  │ nginx:alpine  │  │            │
│  │  │ 10.10.1.10    │  │    │  │ 10.20.1.10    │  │            │
│  │  └───────────────┘  │    │  └───────────────┘  │            │
│  └─────────────────────┘    └─────────────────────┘            │
│                                                                 │
│  ┌─────────────────────────────────────────────────┐           │
│  │  Route53 Private Zone: raj-demo.internal        │           │
│  │  app1.raj-demo.internal → 10.10.1.10            │           │
│  │  app2.raj-demo.internal → 10.20.1.10            │           │
│  └─────────────────────────────────────────────────┘           │
│                                                                 │
│  ┌──────────────────────┐ (optional)                           │
│  │  S3 Bucket           │                                      │
│  │  s3.raj-demo.internal│                                      │
│  └──────────────────────┘                                      │
└─────────────────────────────────────────────────────────────────┘
```

## Structure

```
terraform/
├── providers.tf                    # AWS, TLS, Local providers
├── variables.tf                    # Root variables (VPC maps, DNS, S3 toggles)
├── terraform.tfvars                # Default: 2 VPCs in eu-central-1
├── main.tf                         # Module calls via for_each
├── dns.tf                          # Route53 private zone + A records
├── s3.tf                           # S3 bucket (conditional)
├── outputs.tf                      # VPC IDs, IPs, SSH commands, DNS, S3
├── templates/
│   └── user-data.sh.tpl            # Docker + nginx bootstrap
├── modules/
│   └── aws-vpc/
│       ├── main.tf                 # VPC, subnet, IGW, RT, SG, ENI, EIP, EC2, TGW
│       ├── variables.tf            # Per-resource naming variables
│       └── outputs.tf              # IDs, IPs, RT for TGW injection
├── scripts/
│   ├── sandbox_api.py              # CSP sandbox API client
│   ├── create_sandbox.py           # Create Infoblox sandbox
│   ├── create_user.py              # Create sandbox user
│   ├── deploy_api_key.py           # Deploy API key
│   ├── delete_user.py              # Cleanup: delete user
│   └── delete_sandbox.py           # Cleanup: delete sandbox
└── web/
    └── index.html                  # Reference copy of welcome page
```

## Usage

### Quick Start

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

### Adding a Third VPC

Edit `terraform.tfvars` and add an entry to `EU_Central_FrontEnd`:

```hcl
  VPC3 = {
    aws_vpc_name          = "RajDemoVpc3"
    igw_name              = "RajDemoVpc3-IGW"
    rt_name               = "RajDemoVpc3-RT"
    aws_subnet_name       = "RajDemoVpc3-Subnet"
    private_ip            = "10.30.1.10"
    app_fqdn              = "app3.raj-demo.internal"
    aws_ec2_name          = "RajDemoWeb3"
    aws_ec2_key_pair_name = "EU_Central_RajDemo3"
    aws_vpc_cidr          = "10.30.0.0/16"
    aws_subnet_cidr       = "10.30.1.0/24"
  }
```

Then `terraform apply`.

### Enabling S3

Set in `terraform.tfvars`:

```hcl
enable_s3_bucket = true
s3_bucket_name   = "my-unique-bucket-name"
```

### Variable Structure

Each VPC is defined as a map entry with full control over resource naming:

| Field | Purpose | Example |
|-------|---------|---------|
| `aws_vpc_name` | VPC Name tag | `RajDemoVpc1` |
| `igw_name` | Internet Gateway Name tag | `RajDemoVpc1-IGW` |
| `rt_name` | Route Table Name tag | `RajDemoVpc1-RT` |
| `aws_subnet_name` | Subnet Name tag | `RajDemoVpc1-Subnet` |
| `private_ip` | Static private IP for EC2 | `10.10.1.10` |
| `app_fqdn` | DNS A record FQDN | `app1.raj-demo.internal` |
| `aws_ec2_name` | EC2 instance Name tag | `RajDemoWeb1` |
| `aws_ec2_key_pair_name` | SSH key pair name | `EU_Central_RajDemo1` |
| `aws_vpc_cidr` | VPC CIDR | `10.10.0.0/16` |
| `aws_subnet_cidr` | Subnet CIDR | `10.10.1.0/24` |

### Module Outputs (for TGW / cross-VPC patterns)

The module exposes `rt_id`, `aws_vpc_id`, `aws_vpc_cidr`, `subnet_id` — everything needed for Transit Gateway attachments, VPC peering, or route injection.

## Cleanup

```bash
terraform destroy -auto-approve
```
