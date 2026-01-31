# AWS Tech Summit — Infoblox UAI3 Lab

Modular Terraform for deploying multi-VPC environments with Docker web apps, Route53 private DNS, and optional S3.

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  AWS Account  (eu-central-1)                                     │
│                                                                  │
│  ┌──────────────────────┐     ┌──────────────────────┐          │
│  │  RajDemoVpc1          │     │  RajDemoVpc2          │  + VPC N│
│  │  10.10.0.0/16         │     │  10.20.0.0/16         │         │
│  │  ┌──────────────────┐ │     │  ┌──────────────────┐ │         │
│  │  │  RajDemoWeb1     │ │     │  │  RajDemoWeb2     │ │         │
│  │  │  Docker + nginx  │ │     │  │  Docker + nginx  │ │         │
│  │  │  10.10.1.10      │ │     │  │  10.20.1.10      │ │         │
│  │  └──────────────────┘ │     │  └──────────────────┘ │         │
│  └──────────────────────┘     └──────────────────────┘          │
│                                                                  │
│  ┌──────────────────────────────────────────────────────┐       │
│  │  Route53 Private Zone: raj-demo.internal              │       │
│  │    app1.raj-demo.internal → 10.10.1.10                │       │
│  │    app2.raj-demo.internal → 10.20.1.10                │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                  │
│  ┌────────────────────┐  (optional)                             │
│  │  S3 Bucket          │                                         │
│  │  CNAME → s3.raj-demo.internal                                │
│  └────────────────────┘                                         │
└──────────────────────────────────────────────────────────────────┘
```

## Structure

```
├── Makefile                           # make plan / apply / destroy / fmt / validate
├── .gitignore                         # PEM, tfstate, .terraform excluded
├── terraform/
│   ├── providers.tf                   # AWS provider + default_tags + required_version
│   ├── variables.tf                   # VPC map, DNS, S3 toggles (with validation)
│   ├── terraform.tfvars               # Default: 2 VPCs in eu-central-1
│   ├── main.tf                        # AMI lookup (once) + module for_each
│   ├── dns.tf                         # Route53 private zone + A records via for_each
│   ├── s3.tf                          # S3 bucket + policy + CNAME (conditional)
│   ├── outputs.tf                     # Structured maps for all resource IDs and IPs
│   ├── templates/
│   │   └── user-data.sh.tpl           # Docker + nginx:alpine bootstrap
│   └── modules/
│       └── aws-vpc/
│           ├── main.tf                # VPC → Subnet → IGW → RT → SG → ENI → EC2 → EIP
│           ├── variables.tf           # Typed inputs with CIDR/IP validation
│           └── outputs.tf             # IDs, IPs, RT (TGW-injectable)
├── scripts/                           # Infoblox CSP lifecycle scripts
└── web/
    └── index.html                     # Reference welcome page
```

## Quick Start

```bash
make plan      # terraform init + plan
make apply     # terraform init + apply -auto-approve
make destroy   # terraform destroy -auto-approve
make fmt       # format all .tf files
make validate  # syntax + validation check
```

## Extending

### Add a VPC

Add an entry to `EU_Central_FrontEnd` in `terraform.tfvars`:

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

Then `make apply`. The DNS record, VPC association, and all resources are created automatically.

### Enable S3

```hcl
enable_s3_bucket = true
s3_bucket_name   = "my-globally-unique-name"
```

### Module Outputs for TGW / Peering

```hcl
module.aws_instances_eu_central["VPC1"].route_table_id   # inject TGW routes
module.aws_instances_eu_central["VPC1"].vpc_id           # TGW attachment
module.aws_instances_eu_central["VPC1"].subnet_id        # TGW attachment
module.aws_instances_eu_central["VPC1"].vpc_cidr         # TGW route destination
```

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| AMI lookup at root, not in module | Single API call, consistent AMI across all VPCs |
| `default_tags` in provider | Tags applied globally — no repetition per resource |
| Route table always created | Even without IGW, TGW/peering routes need a target RT |
| `for_each` for DNS records | Stable keys — adding/removing VPCs won't shift other records |
| `bool` types for toggles | Native HCL — no string comparison hacks |
| `internet` toggle on module | Same module works for public VPCs and private-only VPCs |
| TGW at root, not in module | TGW is a shared regional resource, not per-VPC |
| Variable validation | Catches CIDR/IP errors at `plan` time, not `apply` |
