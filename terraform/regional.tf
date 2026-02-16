# ============================================================
# Per-region resources: NAT Gateway + VPN Gateway
# Placed in the first VPC of each region (3 tokens per region)
# ============================================================

# --- us-east-1 ---

resource "aws_eip" "nat_us_east_1" {
  provider = aws.us_east_1
  domain   = "vpc"
  tags     = { Name = "UAI3-USE1-NAT-EIP" }
}

resource "aws_nat_gateway" "us_east_1" {
  provider      = aws.us_east_1
  allocation_id = aws_eip.nat_us_east_1.id
  subnet_id     = module.vpcs_us_east_1["VPC1"].subnet_id
  tags          = { Name = "UAI3-USE1-NAT" }
}

resource "aws_vpn_gateway" "us_east_1" {
  provider = aws.us_east_1
  vpc_id   = module.vpcs_us_east_1["VPC1"].vpc_id
  tags     = { Name = "UAI3-USE1-VGW" }
}

# --- us-west-2 ---

resource "aws_eip" "nat_us_west_2" {
  provider = aws.us_west_2
  domain   = "vpc"
  tags     = { Name = "UAI3-USW2-NAT-EIP" }
}

resource "aws_nat_gateway" "us_west_2" {
  provider      = aws.us_west_2
  allocation_id = aws_eip.nat_us_west_2.id
  subnet_id     = module.vpcs_us_west_2["VPC1"].subnet_id
  tags          = { Name = "UAI3-USW2-NAT" }
}

resource "aws_vpn_gateway" "us_west_2" {
  provider = aws.us_west_2
  vpc_id   = module.vpcs_us_west_2["VPC1"].vpc_id
  tags     = { Name = "UAI3-USW2-VGW" }
}

# --- eu-central-1 (default provider) ---

resource "aws_eip" "nat_eu_central_1" {
  domain = "vpc"
  tags   = { Name = "UAI3-EUC1-NAT-EIP" }
}

resource "aws_nat_gateway" "eu_central_1" {
  allocation_id = aws_eip.nat_eu_central_1.id
  subnet_id     = module.vpcs_eu_central_1["VPC1"].subnet_id
  tags          = { Name = "UAI3-EUC1-NAT" }
}

resource "aws_vpn_gateway" "eu_central_1" {
  vpc_id = module.vpcs_eu_central_1["VPC1"].vpc_id
  tags   = { Name = "UAI3-EUC1-VGW" }
}

# --- eu-west-1 ---

resource "aws_eip" "nat_eu_west_1" {
  provider = aws.eu_west_1
  domain   = "vpc"
  tags     = { Name = "UAI3-EUW1-NAT-EIP" }
}

resource "aws_nat_gateway" "eu_west_1" {
  provider      = aws.eu_west_1
  allocation_id = aws_eip.nat_eu_west_1.id
  subnet_id     = module.vpcs_eu_west_1["VPC1"].subnet_id
  tags          = { Name = "UAI3-EUW1-NAT" }
}

resource "aws_vpn_gateway" "eu_west_1" {
  provider = aws.eu_west_1
  vpc_id   = module.vpcs_eu_west_1["VPC1"].vpc_id
  tags     = { Name = "UAI3-EUW1-VGW" }
}

# --- ap-southeast-1 ---

resource "aws_eip" "nat_ap_southeast_1" {
  provider = aws.ap_southeast_1
  domain   = "vpc"
  tags     = { Name = "UAI3-APSE1-NAT-EIP" }
}

resource "aws_nat_gateway" "ap_southeast_1" {
  provider      = aws.ap_southeast_1
  allocation_id = aws_eip.nat_ap_southeast_1.id
  subnet_id     = module.vpcs_ap_southeast_1["VPC1"].subnet_id
  tags          = { Name = "UAI3-APSE1-NAT" }
}

resource "aws_vpn_gateway" "ap_southeast_1" {
  provider = aws.ap_southeast_1
  vpc_id   = module.vpcs_ap_southeast_1["VPC1"].vpc_id
  tags     = { Name = "UAI3-APSE1-VGW" }
}

# --- ap-northeast-1 ---

resource "aws_eip" "nat_ap_northeast_1" {
  provider = aws.ap_northeast_1
  domain   = "vpc"
  tags     = { Name = "UAI3-APNE1-NAT-EIP" }
}

resource "aws_nat_gateway" "ap_northeast_1" {
  provider      = aws.ap_northeast_1
  allocation_id = aws_eip.nat_ap_northeast_1.id
  subnet_id     = module.vpcs_ap_northeast_1["VPC1"].subnet_id
  tags          = { Name = "UAI3-APNE1-NAT" }
}

resource "aws_vpn_gateway" "ap_northeast_1" {
  provider = aws.ap_northeast_1
  vpc_id   = module.vpcs_ap_northeast_1["VPC1"].vpc_id
  tags     = { Name = "UAI3-APNE1-VGW" }
}

# --- sa-east-1 ---

resource "aws_eip" "nat_sa_east_1" {
  provider = aws.sa_east_1
  domain   = "vpc"
  tags     = { Name = "UAI3-SAE1-NAT-EIP" }
}

resource "aws_nat_gateway" "sa_east_1" {
  provider      = aws.sa_east_1
  allocation_id = aws_eip.nat_sa_east_1.id
  subnet_id     = module.vpcs_sa_east_1["VPC1"].subnet_id
  tags          = { Name = "UAI3-SAE1-NAT" }
}

resource "aws_vpn_gateway" "sa_east_1" {
  provider = aws.sa_east_1
  vpc_id   = module.vpcs_sa_east_1["VPC1"].vpc_id
  tags     = { Name = "UAI3-SAE1-VGW" }
}

# --- ca-central-1 ---

resource "aws_eip" "nat_ca_central_1" {
  provider = aws.ca_central_1
  domain   = "vpc"
  tags     = { Name = "UAI3-CAC1-NAT-EIP" }
}

resource "aws_nat_gateway" "ca_central_1" {
  provider      = aws.ca_central_1
  allocation_id = aws_eip.nat_ca_central_1.id
  subnet_id     = module.vpcs_ca_central_1["VPC1"].subnet_id
  tags          = { Name = "UAI3-CAC1-NAT" }
}

resource "aws_vpn_gateway" "ca_central_1" {
  provider = aws.ca_central_1
  vpc_id   = module.vpcs_ca_central_1["VPC1"].vpc_id
  tags     = { Name = "UAI3-CAC1-VGW" }
}

# --- ap-south-1 ---

resource "aws_eip" "nat_ap_south_1" {
  provider = aws.ap_south_1
  domain   = "vpc"
  tags     = { Name = "UAI3-APS1-NAT-EIP" }
}

resource "aws_nat_gateway" "ap_south_1" {
  provider      = aws.ap_south_1
  allocation_id = aws_eip.nat_ap_south_1.id
  subnet_id     = module.vpcs_ap_south_1["VPC1"].subnet_id
  tags          = { Name = "UAI3-APS1-NAT" }
}

resource "aws_vpn_gateway" "ap_south_1" {
  provider = aws.ap_south_1
  vpc_id   = module.vpcs_ap_south_1["VPC1"].vpc_id
  tags     = { Name = "UAI3-APS1-VGW" }
}

# --- eu-north-1 ---

resource "aws_eip" "nat_eu_north_1" {
  provider = aws.eu_north_1
  domain   = "vpc"
  tags     = { Name = "UAI3-EUN1-NAT-EIP" }
}

resource "aws_nat_gateway" "eu_north_1" {
  provider      = aws.eu_north_1
  allocation_id = aws_eip.nat_eu_north_1.id
  subnet_id     = module.vpcs_eu_north_1["VPC1"].subnet_id
  tags          = { Name = "UAI3-EUN1-NAT" }
}

resource "aws_vpn_gateway" "eu_north_1" {
  provider = aws.eu_north_1
  vpc_id   = module.vpcs_eu_north_1["VPC1"].vpc_id
  tags     = { Name = "UAI3-EUN1-VGW" }
}
