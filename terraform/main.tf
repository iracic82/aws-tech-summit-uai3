# --- Default user data from template ---

locals {
  default_user_data = templatefile("${path.module}/templates/user-data.sh.tpl", {})
}

# --- Region configuration ---
# Each region: short name, CIDR base (tens digit), provider alias key

locals {
  region_configs = {
    "us-east-1"      = { short = "USE1", cidr_base = 10 }
    "us-west-2"      = { short = "USW2", cidr_base = 20 }
    "eu-central-1"   = { short = "EUC1", cidr_base = 30 }
    "eu-west-1"      = { short = "EUW1", cidr_base = 40 }
    "ap-southeast-1" = { short = "APSE1", cidr_base = 50 }
    "ap-northeast-1" = { short = "APNE1", cidr_base = 60 }
    "sa-east-1"      = { short = "SAE1", cidr_base = 70 }
    "ca-central-1"   = { short = "CAC1", cidr_base = 80 }
    "ap-south-1"     = { short = "APS1", cidr_base = 90 }
    "eu-north-1"     = { short = "EUN1", cidr_base = 100 }
  }
}

# --- Generate all VPC configs programmatically ---
# 4 VPCs per region, CIDRs derived from region's base index

locals {
  all_vpcs = {
    for region, cfg in local.region_configs : region => {
      for i in range(1, var.vpcs_per_region + 1) : "VPC${i}" => {
        aws_vpc_name          = "UAI3-${cfg.short}-Vpc${i}"
        aws_vpc_cidr          = "10.${cfg.cidr_base + i - 1}.0.0/16"
        aws_subnet_name       = "UAI3-${cfg.short}-Vpc${i}-Subnet"
        aws_subnet_cidr       = "10.${cfg.cidr_base + i - 1}.1.0/24"
        igw_name              = "UAI3-${cfg.short}-Vpc${i}-IGW"
        rt_name               = "UAI3-${cfg.short}-Vpc${i}-RT"
        private_ip            = "10.${cfg.cidr_base + i - 1}.1.10"
        aws_ec2_name          = "UAI3-${cfg.short}-Web${i}"
        aws_ec2_key_pair_name = "UAI3_${cfg.short}_${i}"
        app_fqdn              = "app${i}.${lower(cfg.short)}.${var.route53_domain_name}"
        region                = region
      }
    }
  }
}

# ============================================================
# Per-region module blocks (one per region — provider is static)
# ============================================================

# --- us-east-1 ---

module "vpcs_us_east_1" {
  source   = "./modules/aws-vpc"
  for_each = local.all_vpcs["us-east-1"]

  providers = { aws = aws.us_east_1 }

  aws_vpc_name          = each.value.aws_vpc_name
  aws_vpc_cidr          = each.value.aws_vpc_cidr
  aws_subnet_name       = each.value.aws_subnet_name
  aws_subnet_cidr       = each.value.aws_subnet_cidr
  igw_name              = each.value.igw_name
  rt_name               = each.value.rt_name
  private_ip            = each.value.private_ip
  aws_ec2_name          = each.value.aws_ec2_name
  aws_ec2_key_pair_name = each.value.aws_ec2_key_pair_name
  user_data             = local.default_user_data
  internet              = true
}

# --- us-west-2 ---

module "vpcs_us_west_2" {
  source   = "./modules/aws-vpc"
  for_each = local.all_vpcs["us-west-2"]

  providers = { aws = aws.us_west_2 }

  aws_vpc_name          = each.value.aws_vpc_name
  aws_vpc_cidr          = each.value.aws_vpc_cidr
  aws_subnet_name       = each.value.aws_subnet_name
  aws_subnet_cidr       = each.value.aws_subnet_cidr
  igw_name              = each.value.igw_name
  rt_name               = each.value.rt_name
  private_ip            = each.value.private_ip
  aws_ec2_name          = each.value.aws_ec2_name
  aws_ec2_key_pair_name = each.value.aws_ec2_key_pair_name
  user_data             = local.default_user_data
  internet              = true
}

# --- eu-central-1 (default provider) ---

module "vpcs_eu_central_1" {
  source   = "./modules/aws-vpc"
  for_each = local.all_vpcs["eu-central-1"]

  aws_vpc_name          = each.value.aws_vpc_name
  aws_vpc_cidr          = each.value.aws_vpc_cidr
  aws_subnet_name       = each.value.aws_subnet_name
  aws_subnet_cidr       = each.value.aws_subnet_cidr
  igw_name              = each.value.igw_name
  rt_name               = each.value.rt_name
  private_ip            = each.value.private_ip
  aws_ec2_name          = each.value.aws_ec2_name
  aws_ec2_key_pair_name = each.value.aws_ec2_key_pair_name
  user_data             = local.default_user_data
  internet              = true
}

# --- eu-west-1 ---

module "vpcs_eu_west_1" {
  source   = "./modules/aws-vpc"
  for_each = local.all_vpcs["eu-west-1"]

  providers = { aws = aws.eu_west_1 }

  aws_vpc_name          = each.value.aws_vpc_name
  aws_vpc_cidr          = each.value.aws_vpc_cidr
  aws_subnet_name       = each.value.aws_subnet_name
  aws_subnet_cidr       = each.value.aws_subnet_cidr
  igw_name              = each.value.igw_name
  rt_name               = each.value.rt_name
  private_ip            = each.value.private_ip
  aws_ec2_name          = each.value.aws_ec2_name
  aws_ec2_key_pair_name = each.value.aws_ec2_key_pair_name
  user_data             = local.default_user_data
  internet              = true
}

# --- ap-southeast-1 ---

module "vpcs_ap_southeast_1" {
  source   = "./modules/aws-vpc"
  for_each = local.all_vpcs["ap-southeast-1"]

  providers = { aws = aws.ap_southeast_1 }

  aws_vpc_name          = each.value.aws_vpc_name
  aws_vpc_cidr          = each.value.aws_vpc_cidr
  aws_subnet_name       = each.value.aws_subnet_name
  aws_subnet_cidr       = each.value.aws_subnet_cidr
  igw_name              = each.value.igw_name
  rt_name               = each.value.rt_name
  private_ip            = each.value.private_ip
  aws_ec2_name          = each.value.aws_ec2_name
  aws_ec2_key_pair_name = each.value.aws_ec2_key_pair_name
  user_data             = local.default_user_data
  internet              = true
}

# --- ap-northeast-1 ---

module "vpcs_ap_northeast_1" {
  source   = "./modules/aws-vpc"
  for_each = local.all_vpcs["ap-northeast-1"]

  providers = { aws = aws.ap_northeast_1 }

  aws_vpc_name          = each.value.aws_vpc_name
  aws_vpc_cidr          = each.value.aws_vpc_cidr
  aws_subnet_name       = each.value.aws_subnet_name
  aws_subnet_cidr       = each.value.aws_subnet_cidr
  igw_name              = each.value.igw_name
  rt_name               = each.value.rt_name
  private_ip            = each.value.private_ip
  aws_ec2_name          = each.value.aws_ec2_name
  aws_ec2_key_pair_name = each.value.aws_ec2_key_pair_name
  user_data             = local.default_user_data
  internet              = true
}

# --- sa-east-1 ---

module "vpcs_sa_east_1" {
  source   = "./modules/aws-vpc"
  for_each = local.all_vpcs["sa-east-1"]

  providers = { aws = aws.sa_east_1 }

  aws_vpc_name          = each.value.aws_vpc_name
  aws_vpc_cidr          = each.value.aws_vpc_cidr
  aws_subnet_name       = each.value.aws_subnet_name
  aws_subnet_cidr       = each.value.aws_subnet_cidr
  igw_name              = each.value.igw_name
  rt_name               = each.value.rt_name
  private_ip            = each.value.private_ip
  aws_ec2_name          = each.value.aws_ec2_name
  aws_ec2_key_pair_name = each.value.aws_ec2_key_pair_name
  user_data             = local.default_user_data
  internet              = true
}

# --- ca-central-1 ---

module "vpcs_ca_central_1" {
  source   = "./modules/aws-vpc"
  for_each = local.all_vpcs["ca-central-1"]

  providers = { aws = aws.ca_central_1 }

  aws_vpc_name          = each.value.aws_vpc_name
  aws_vpc_cidr          = each.value.aws_vpc_cidr
  aws_subnet_name       = each.value.aws_subnet_name
  aws_subnet_cidr       = each.value.aws_subnet_cidr
  igw_name              = each.value.igw_name
  rt_name               = each.value.rt_name
  private_ip            = each.value.private_ip
  aws_ec2_name          = each.value.aws_ec2_name
  aws_ec2_key_pair_name = each.value.aws_ec2_key_pair_name
  user_data             = local.default_user_data
  internet              = true
}

# --- ap-south-1 ---

module "vpcs_ap_south_1" {
  source   = "./modules/aws-vpc"
  for_each = local.all_vpcs["ap-south-1"]

  providers = { aws = aws.ap_south_1 }

  aws_vpc_name          = each.value.aws_vpc_name
  aws_vpc_cidr          = each.value.aws_vpc_cidr
  aws_subnet_name       = each.value.aws_subnet_name
  aws_subnet_cidr       = each.value.aws_subnet_cidr
  igw_name              = each.value.igw_name
  rt_name               = each.value.rt_name
  private_ip            = each.value.private_ip
  aws_ec2_name          = each.value.aws_ec2_name
  aws_ec2_key_pair_name = each.value.aws_ec2_key_pair_name
  user_data             = local.default_user_data
  internet              = true
}

# --- eu-north-1 ---

module "vpcs_eu_north_1" {
  source   = "./modules/aws-vpc"
  for_each = local.all_vpcs["eu-north-1"]

  providers = { aws = aws.eu_north_1 }

  aws_vpc_name          = each.value.aws_vpc_name
  aws_vpc_cidr          = each.value.aws_vpc_cidr
  aws_subnet_name       = each.value.aws_subnet_name
  aws_subnet_cidr       = each.value.aws_subnet_cidr
  igw_name              = each.value.igw_name
  rt_name               = each.value.rt_name
  private_ip            = each.value.private_ip
  aws_ec2_name          = each.value.aws_ec2_name
  aws_ec2_key_pair_name = each.value.aws_ec2_key_pair_name
  user_data             = local.default_user_data
  internet              = true
}

# ============================================================
# Merged module outputs (flat map for outputs + DNS)
# ============================================================

locals {
  all_modules = merge(
    { for k, v in module.vpcs_us_east_1 :      "us-east-1/${k}" => v },
    { for k, v in module.vpcs_us_west_2 :      "us-west-2/${k}" => v },
    { for k, v in module.vpcs_eu_central_1 :   "eu-central-1/${k}" => v },
    { for k, v in module.vpcs_eu_west_1 :      "eu-west-1/${k}" => v },
    { for k, v in module.vpcs_ap_southeast_1 : "ap-southeast-1/${k}" => v },
    { for k, v in module.vpcs_ap_northeast_1 : "ap-northeast-1/${k}" => v },
    { for k, v in module.vpcs_sa_east_1 :      "sa-east-1/${k}" => v },
    { for k, v in module.vpcs_ca_central_1 :   "ca-central-1/${k}" => v },
    { for k, v in module.vpcs_ap_south_1 :     "ap-south-1/${k}" => v },
    { for k, v in module.vpcs_eu_north_1 :     "eu-north-1/${k}" => v },
  )

  # VPC associations for Route53 (vpc_id + region)
  all_vpc_associations = merge(
    { for k, v in module.vpcs_us_east_1 :      "us-east-1/${k}" => { vpc_id = v.vpc_id, region = "us-east-1" } },
    { for k, v in module.vpcs_us_west_2 :      "us-west-2/${k}" => { vpc_id = v.vpc_id, region = "us-west-2" } },
    { for k, v in module.vpcs_eu_central_1 :   "eu-central-1/${k}" => { vpc_id = v.vpc_id, region = "eu-central-1" } },
    { for k, v in module.vpcs_eu_west_1 :      "eu-west-1/${k}" => { vpc_id = v.vpc_id, region = "eu-west-1" } },
    { for k, v in module.vpcs_ap_southeast_1 : "ap-southeast-1/${k}" => { vpc_id = v.vpc_id, region = "ap-southeast-1" } },
    { for k, v in module.vpcs_ap_northeast_1 : "ap-northeast-1/${k}" => { vpc_id = v.vpc_id, region = "ap-northeast-1" } },
    { for k, v in module.vpcs_sa_east_1 :      "sa-east-1/${k}" => { vpc_id = v.vpc_id, region = "sa-east-1" } },
    { for k, v in module.vpcs_ca_central_1 :   "ca-central-1/${k}" => { vpc_id = v.vpc_id, region = "ca-central-1" } },
    { for k, v in module.vpcs_ap_south_1 :     "ap-south-1/${k}" => { vpc_id = v.vpc_id, region = "ap-south-1" } },
    { for k, v in module.vpcs_eu_north_1 :     "eu-north-1/${k}" => { vpc_id = v.vpc_id, region = "eu-north-1" } },
  )
}
