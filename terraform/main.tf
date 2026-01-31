# --- AMI lookup (resolved ONCE, passed to all modules) ---

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

# --- Default user data from template ---

locals {
  default_user_data = templatefile("${path.module}/templates/user-data.sh.tpl", {})
}

# --- Deploy VPC + EC2 via for_each ---

module "aws_instances_eu_central" {
  source   = "./modules/aws-vpc"
  for_each = var.EU_Central_FrontEnd

  aws_vpc_name          = each.value.aws_vpc_name
  aws_vpc_cidr          = each.value.aws_vpc_cidr
  aws_subnet_name       = each.value.aws_subnet_name
  aws_subnet_cidr       = each.value.aws_subnet_cidr
  igw_name              = each.value.igw_name
  rt_name               = each.value.rt_name
  private_ip            = each.value.private_ip
  aws_ec2_name          = each.value.aws_ec2_name
  aws_ec2_key_pair_name = each.value.aws_ec2_key_pair_name
  ami_id                = data.aws_ami.amazon_linux_2023.id
  user_data             = local.default_user_data
  internet              = true
}
