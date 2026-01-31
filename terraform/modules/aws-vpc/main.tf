terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.20"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# --- VPC ---

resource "aws_vpc" "this" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.aws_vpc_name }
}

# --- Subnet ---

resource "aws_subnet" "this" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.aws_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = var.aws_subnet_name }
}

# --- Internet Gateway (conditional) ---

resource "aws_internet_gateway" "this" {
  count  = var.internet ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = { Name = var.igw_name }
}

# --- Route Table (always created — TGW/peering route injection compatible) ---

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = var.rt_name }
}

resource "aws_route_table_association" "this" {
  route_table_id = aws_route_table.this.id
  subnet_id      = aws_subnet.this.id
}

# --- Default Route via IGW (conditional) ---

resource "aws_route" "igw_default" {
  count                  = var.internet ? 1 : 0
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

# --- Security Group ---

resource "aws_security_group" "this" {
  name        = "${var.aws_vpc_name}-sg"
  description = "Allow SSH, HTTP, HTTPS, ICMP inbound — all outbound"
  vpc_id      = aws_vpc.this.id

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

  tags = { Name = "${var.aws_vpc_name}-sg" }
}

# --- Network Interface (static private IP) ---

resource "aws_network_interface" "this" {
  subnet_id       = aws_subnet.this.id
  private_ips     = [var.private_ip]
  security_groups = [aws_security_group.this.id]

  tags = { Name = "${var.aws_ec2_name}-eni" }
}

# --- SSH Key Pair (TLS-generated) ---

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = var.aws_ec2_key_pair_name
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_sensitive_file" "pem" {
  content         = tls_private_key.this.private_key_pem
  filename        = "${path.root}/${var.aws_ec2_key_pair_name}.pem"
  file_permission = "0400"
}

# --- EC2 Instance ---

resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.aws_ec2_instance_type
  key_name      = aws_key_pair.this.key_name

  network_interface {
    network_interface_id = aws_network_interface.this.id
    device_index         = 0
  }

  user_data = var.user_data != "" ? var.user_data : null

  tags = { Name = var.aws_ec2_name }

  depends_on = [aws_internet_gateway.this]
}

# --- Elastic IP ---

resource "aws_eip" "this" {
  domain                    = "vpc"
  instance                  = aws_instance.this.id
  associate_with_private_ip = var.private_ip

  tags = { Name = "${var.aws_ec2_name}-eip" }

  depends_on = [aws_internet_gateway.this]
}
