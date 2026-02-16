# AWS Tech Summit — Infoblox UAI3 Lab

Multi-region Terraform deploying **40 VPCs across 10 AWS regions** with ALBs, NAT/VPN Gateways, Docker web apps, Route53 private DNS, and optional S3. Designed to generate **~550 Infoblox management tokens** for Cloud Discovery demos.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  AWS Account — 10 Regions × 4 VPCs = 40 VPCs                               │
│                                                                             │
│  ┌─ us-east-1 ───────────┐  ┌─ us-west-2 ───────────┐  ┌─ eu-central-1 ─┐│
│  │ VPC1  10.10.0.0/16    │  │ VPC1  10.20.0.0/16    │  │ VPC1 10.30.0.0 ││
│  │ VPC2  10.11.0.0/16    │  │ VPC2  10.21.0.0/16    │  │ VPC2 10.31.0.0 ││
│  │ VPC3  10.12.0.0/16    │  │ VPC3  10.22.0.0/16    │  │ VPC3 10.32.0.0 ││
│  │ VPC4  10.13.0.0/16    │  │ VPC4  10.23.0.0/16    │  │ VPC4 10.33.0.0 ││
│  │ + NAT GW, VPN GW      │  │ + NAT GW, VPN GW      │  │ + NAT GW, VPN  ││
│  └────────────────────────┘  └────────────────────────┘  └────────────────┘│
│                                                                             │
│  ┌─ eu-west-1 ──┐ ┌─ ap-southeast-1 ┐ ┌─ ap-northeast-1 ┐ ┌─ sa-east-1 ─┐│
│  │ 4 VPCs       │ │ 4 VPCs          │ │ 4 VPCs          │ │ 4 VPCs      ││
│  │ 10.40-43.x.x │ │ 10.50-53.x.x   │ │ 10.60-63.x.x   │ │ 10.70-73.x  ││
│  └──────────────┘ └─────────────────┘ └─────────────────┘ └─────────────┘│
│                                                                             │
│  ┌─ ca-central-1 ┐ ┌─ ap-south-1 ───┐ ┌─ eu-north-1 ───┐                 │
│  │ 4 VPCs        │ │ 4 VPCs         │ │ 4 VPCs         │                 │
│  │ 10.80-83.x.x  │ │ 10.90-93.x.x  │ │ 10.100-103.x.x │                 │
│  └───────────────┘ └────────────────┘ └────────────────┘                 │
│                                                                             │
│  Per VPC: EC2 + EIP + ENI + IGW + ALB + 3 extra ENIs + 3 extra EIPs       │
│  Per Region: NAT Gateway + NAT EIP + VPN Gateway                           │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────┐              │
│  │  Route53 Private Zone: uai3.internal                      │              │
│  │  40 A records: app{1-4}.{region}.uai3.internal            │              │
│  └──────────────────────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Regions

| # | Region | Short | CIDR Range | VPCs |
|---|--------|-------|------------|------|
| 1 | us-east-1 | USE1 | 10.10-13.x.x | 4 |
| 2 | us-west-2 | USW2 | 10.20-23.x.x | 4 |
| 3 | eu-central-1 | EUC1 | 10.30-33.x.x | 4 |
| 4 | eu-west-1 | EUW1 | 10.40-43.x.x | 4 |
| 5 | ap-southeast-1 | APSE1 | 10.50-53.x.x | 4 |
| 6 | ap-northeast-1 | APNE1 | 10.60-63.x.x | 4 |
| 7 | sa-east-1 | SAE1 | 10.70-73.x.x | 4 |
| 8 | ca-central-1 | CAC1 | 10.80-83.x.x | 4 |
| 9 | ap-south-1 | APS1 | 10.90-93.x.x | 4 |
| 10 | eu-north-1 | EUN1 | 10.100-103.x.x | 4 |

## Management Token Count

| Resource | Per VPC | × 40 VPCs |
|----------|---------|-----------|
| EC2 instance | 1 | 40 |
| EC2 EIP | 1 | 40 |
| EC2 ENI | 1 | 40 |
| IGW | 1 | 40 |
| ALB (+2 auto ENIs) | ~3 | ~120 |
| 3 extra ENIs | 3 | 120 |
| 3 extra EIPs | 3 | 120 |
| **Per-VPC subtotal** | **~13** | **~520** |

| Resource | Per Region | × 10 Regions |
|----------|-----------|--------------|
| NAT Gateway | 1 | 10 |
| NAT EIP | 1 | 10 |
| VPN Gateway | 1 | 10 |
| **Per-region subtotal** | **3** | **30** |

**Grand Total: ~550 management tokens** | ~1,071 Terraform resources

## Structure

```
├── Makefile
├── terraform/
│   ├── providers.tf          # Default (eu-central-1) + 9 regional aliases
│   ├── variables.tf          # vpcs_per_region, DNS, S3 toggles
│   ├── terraform.tfvars      # vpcs_per_region = 4
│   ├── main.tf               # Locals-generated VPC configs + 10 module blocks
│   ├── regional.tf           # NAT GW + VPN GW per region (30 tokens)
│   ├── dns.tf                # Route53 private zone + 40 A records
│   ├── s3.tf                 # S3 bucket + policy + CNAME (conditional)
│   ├── outputs.tf            # Aggregated outputs from all 10 modules
│   ├── templates/
│   │   └── user-data.sh.tpl  # Docker + nginx:alpine bootstrap
│   └── modules/
│       └── aws-vpc/
│           ├── main.tf       # VPC → 2 Subnets → IGW → RT → SG → ENI → EC2 → EIP → ALB → extra ENIs/EIPs
│           ├── variables.tf  # ami_id (auto-resolve), enable_alb, extra_eni_count
│           └── outputs.tf    # IDs, IPs, ALB DNS name
├── scripts/                  # Infoblox CSP lifecycle scripts
└── web/
    └── index.html            # Reference welcome page
```

## Quick Start

```bash
cd terraform/
terraform init
terraform plan      # verify ~1,071 resources
terraform apply -auto-approve
```

## Scaling

Change `vpcs_per_region` in `terraform.tfvars` to adjust VPC count per region:

```hcl
vpcs_per_region = 2   # 20 VPCs total, ~270 tokens
vpcs_per_region = 4   # 40 VPCs total, ~550 tokens (default)
```

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| AMI lookup inside module | AMI IDs are region-specific — each module resolves its own |
| 10 explicit module blocks | Terraform requires static provider assignment per module |
| Locals-generated VPC configs | 40 VPCs derived from 10 region configs — zero duplication |
| ALB per VPC (2 subnets) | ALB requires 2 AZs — subnet B auto-derived from VPC CIDR |
| Extra ENIs + EIPs per VPC | Maximize management tokens at minimal AWS cost |
| NAT/VPN GW per region | Regional resources placed in first VPC of each region |
| `default_tags` in provider | Tags applied globally — no repetition per resource |
| `for_each` for DNS records | Stable keys — adding/removing VPCs won't shift other records |
