# --- Default user data from template ---

locals {
  default_user_data = templatefile("${path.module}/templates/user-data.sh.tpl", {})
}

# --- Deploy VPC + EC2 modules via for_each ---

module "aws_instances_eu_central" {
  source   = "./modules/aws-vpc"
  for_each = var.EU_Central_FrontEnd

  aws_region            = var.aws_region
  aws_vpc_name          = each.value["aws_vpc_name"]
  aws_subnet_name       = each.value["aws_subnet_name"]
  rt_name               = each.value["rt_name"]
  igw_name              = each.value["igw_name"]
  private_ip            = each.value["private_ip"]
  tgw                   = "false"
  internet              = "true"
  aws_ec2_name          = each.value["aws_ec2_name"]
  aws_ec2_key_pair_name = each.value["aws_ec2_key_pair_name"]
  aws_vpc_cidr          = each.value["aws_vpc_cidr"]
  aws_subnet_cidr       = each.value["aws_subnet_cidr"]
  user_data             = local.default_user_data
  resource_owner        = var.resource_owner
}
