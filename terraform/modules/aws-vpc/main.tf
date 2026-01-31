data "aws_availability_zones" "available" {
  state = "available"
}

# --- VPC ---

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = var.vpc_name }
}

# --- Public Subnet ---

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = { Name = "${var.vpc_name}-public" }
}

# --- Internet Gateway + Route Table (conditional) ---

resource "aws_internet_gateway" "this" {
  count  = var.enable_internet ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.vpc_name}-igw" }
}

resource "aws_route_table" "public" {
  count  = var.enable_internet ? 1 : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = { Name = "${var.vpc_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = var.enable_internet ? 1 : 0
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public[0].id
}

# --- Security Group ---

resource "aws_security_group" "main" {
  name        = "${var.vpc_name}-sg"
  description = "Allow SSH, HTTP, HTTPS, ICMP inbound"
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

  tags = { Name = "${var.vpc_name}-sg" }
}

# --- TLS Key Pair ---

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "${var.key_name_prefix}-${var.vpc_name}-key"
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  filename        = "${path.root}/${var.vpc_name}-key.pem"
  content         = tls_private_key.this.private_key_pem
  file_permission = "0400"
}

# --- ENI with static private IP ---

resource "aws_network_interface" "this" {
  subnet_id       = aws_subnet.public.id
  private_ips     = [var.private_ip]
  security_groups = [aws_security_group.main.id]
  tags = { Name = "${var.instance_name}-eni" }
}

# --- Elastic IP ---

resource "aws_eip" "this" {
  domain = "vpc"
  tags   = { Name = "${var.instance_name}-eip" }
}

resource "aws_eip_association" "this" {
  network_interface_id = aws_network_interface.this.id
  allocation_id        = aws_eip.this.id
  private_ip_address   = var.private_ip
}

# --- EC2 Instance ---

resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.this.key_name

  network_interface {
    network_interface_id = aws_network_interface.this.id
    device_index         = 0
  }

  user_data = var.user_data

  tags = { Name = var.instance_name }

  depends_on = [
    aws_internet_gateway.this
  ]
}
