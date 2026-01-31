# --- Look up Amazon Linux 2023 AMI ---

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Default user data from template ---

locals {
  default_user_data = templatefile("${path.module}/templates/user-data.sh.tpl", {})
}

# --- Deploy VPC + EC2 modules via for_each ---

module "vpc" {
  source   = "./modules/aws-vpc"
  for_each = var.vpcs

  vpc_name      = each.key
  vpc_cidr      = each.value.vpc_cidr
  subnet_cidr   = each.value.subnet_cidr
  instance_name = each.value.instance_name
  instance_type = each.value.instance_type
  private_ip    = each.value.private_ip
  ami_id        = data.aws_ami.amazon_linux.id
  user_data     = each.value.user_data != "" ? each.value.user_data : local.default_user_data
}
