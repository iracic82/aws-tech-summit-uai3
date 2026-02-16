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

# --- AMI lookup (auto-resolve when ami_id is empty) ---

data "aws_ami" "amazon_linux_2023" {
  count       = var.ami_id == "" ? 1 : 0
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

locals {
  resolved_ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023[0].id

  # Auto-derive subnet B CIDR: replace .1.0/24 with .2.0/24 in the VPC CIDR
  subnet_b_cidr = var.subnet_b_cidr != "" ? var.subnet_b_cidr : cidrsubnet(var.aws_vpc_cidr, 8, 2)
}

# --- VPC ---

resource "aws_vpc" "this" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.aws_vpc_name }
}

# --- Subnet A (primary, AZ a) ---

resource "aws_subnet" "this" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.aws_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = var.aws_subnet_name }
}

# --- Subnet B (secondary, AZ b — required for ALB) ---

resource "aws_subnet" "b" {
  count             = var.enable_alb ? 1 : 0
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.subnet_b_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = { Name = "${var.aws_subnet_name}-b" }
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

resource "aws_route_table_association" "b" {
  count          = var.enable_alb ? 1 : 0
  route_table_id = aws_route_table.this.id
  subnet_id      = aws_subnet.b[0].id
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
  description = "Allow SSH, HTTP, HTTPS, ICMP inbound - all outbound"
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
  ami           = local.resolved_ami_id
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

# --- Elastic IP (for EC2) ---

resource "aws_eip" "this" {
  domain                    = "vpc"
  instance                  = aws_instance.this.id
  associate_with_private_ip = var.private_ip

  tags = { Name = "${var.aws_ec2_name}-eip" }

  depends_on = [aws_internet_gateway.this]
}

# --- Extra Standalone ENIs (token generators) ---

resource "aws_network_interface" "extra" {
  count           = var.extra_eni_count
  subnet_id       = aws_subnet.this.id
  security_groups = [aws_security_group.this.id]

  tags = { Name = "${var.aws_vpc_name}-extra-eni-${count.index + 1}" }
}

# --- Extra EIPs (attached to extra ENIs) ---

resource "aws_eip" "extra" {
  count                     = var.extra_eni_count
  domain                    = "vpc"
  network_interface         = aws_network_interface.extra[count.index].id
  associate_with_private_ip = aws_network_interface.extra[count.index].private_ip

  tags = { Name = "${var.aws_vpc_name}-extra-eip-${count.index + 1}" }

  depends_on = [aws_internet_gateway.this]
}

# --- ALB (Application Load Balancer) ---

resource "aws_lb" "this" {
  count              = var.enable_alb ? 1 : 0
  name               = replace("${var.aws_vpc_name}-alb", "/[^a-zA-Z0-9-]/", "-")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = [aws_subnet.this.id, aws_subnet.b[0].id]

  tags = { Name = "${var.aws_vpc_name}-alb" }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_lb_target_group" "this" {
  count    = var.enable_alb ? 1 : 0
  name     = replace("${var.aws_vpc_name}-tg", "/[^a-zA-Z0-9-]/", "-")
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = { Name = "${var.aws_vpc_name}-tg" }
}

resource "aws_lb_target_group_attachment" "this" {
  count            = var.enable_alb ? 1 : 0
  target_group_arn = aws_lb_target_group.this[0].arn
  target_id        = aws_instance.this.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  count             = var.enable_alb ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  tags = { Name = "${var.aws_vpc_name}-listener" }
}
