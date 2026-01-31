terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.20.0"
    }
  }
}

data "aws_availability_zones" "available" {}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# --- VPC ---

resource "aws_vpc" "vpc1" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    "Name"          = var.aws_vpc_name
    "ResourceOwner" = var.resource_owner
  }
}

# --- Subnet ---

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = var.aws_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    "Name"          = var.aws_subnet_name
    "ResourceOwner" = var.resource_owner
  }
}

# --- Internet Gateway (conditional) ---

resource "aws_internet_gateway" "igw" {
  count  = var.internet == "true" ? 1 : 0
  vpc_id = aws_vpc.vpc1.id
  tags = {
    "Name"          = var.igw_name
    "ResourceOwner" = var.resource_owner
  }
}

# --- Route Table (always created for TGW compatibility) ---

resource "aws_route_table" "rt_vpc1" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    "Name"          = var.rt_name
    "ResourceOwner" = var.resource_owner
  }
}

resource "aws_route_table_association" "rt_association_vpc1" {
  route_table_id = aws_route_table.rt_vpc1.id
  subnet_id      = aws_subnet.subnet1.id
}

# --- Default Route via IGW (conditional) ---

resource "aws_route" "route_igw" {
  count                  = var.internet == "true" ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
  route_table_id         = aws_route_table.rt_vpc1.id
}

# --- Security Group ---

resource "aws_security_group" "sg_allow_access_inbound" {
  name   = "${var.aws_vpc_name}-sg"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name"          = "${var.aws_vpc_name}-sg"
    "ResourceOwner" = var.resource_owner
  }
}

# --- Network Interface ---

resource "aws_network_interface" "eth1" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = [var.private_ip]
  security_groups = [aws_security_group.sg_allow_access_inbound.id]
  tags = {
    "Name"          = "${var.aws_ec2_name}-eni"
    "ResourceOwner" = var.resource_owner
  }
}

# --- SSH Key Pair ---

resource "tls_private_key" "demo_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "demo_key_pair" {
  key_name   = var.aws_ec2_key_pair_name
  public_key = tls_private_key.demo_key.public_key_openssh
}

resource "local_sensitive_file" "private_key_pem" {
  content         = tls_private_key.demo_key.private_key_pem
  filename        = "${path.root}/${var.aws_ec2_key_pair_name}.pem"
  file_permission = "0400"
}

# --- EC2 Instance ---

resource "aws_instance" "ec2_linux" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.aws_ec2_instance_type
  key_name      = var.aws_ec2_key_pair_name

  network_interface {
    network_interface_id = aws_network_interface.eth1.id
    device_index         = 0
  }

  user_data = var.user_data

  tags = {
    "Name"          = var.aws_ec2_name
    "ResourceOwner" = var.resource_owner
  }

  depends_on = [aws_key_pair.demo_key_pair, aws_internet_gateway.igw]
}

# --- Elastic IP ---

resource "aws_eip" "eip" {
  domain                    = "vpc"
  instance                  = aws_instance.ec2_linux.id
  associate_with_private_ip = var.private_ip
  depends_on                = [aws_internet_gateway.igw]
  tags = {
    "Name"          = "${var.aws_ec2_name}-eip"
    "ResourceOwner" = var.resource_owner
  }
}

# --- Transit Gateway (conditional) ---

resource "aws_ec2_transit_gateway" "tgw_demo" {
  count       = var.tgw == "true" ? 1 : 0
  description = "${var.aws_vpc_name}-TGW"
  tags = {
    "Name"          = "${var.aws_vpc_name}-TGW"
    "ResourceOwner" = var.resource_owner
  }
}
