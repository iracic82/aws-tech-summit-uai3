aws_region = "eu-central-1"
dns_domain = "raj-demo.internal"

vpcs = {
  "raj-demo-vpc-1" = {
    vpc_cidr      = "10.10.0.0/16"
    subnet_cidr   = "10.10.1.0/24"
    instance_name = "raj-demo-web-1"
    instance_type = "t3.micro"
    private_ip    = "10.10.1.10"
    user_data     = ""
  }
  "raj-demo-vpc-2" = {
    vpc_cidr      = "10.20.0.0/16"
    subnet_cidr   = "10.20.1.0/24"
    instance_name = "raj-demo-web-2"
    instance_type = "t3.micro"
    private_ip    = "10.20.1.10"
    user_data     = ""
  }
}

dns_records = {
  "app1" = {
    subdomain = "app1"
    vpc_key   = "raj-demo-vpc-1"
  }
  "app2" = {
    subdomain = "app2"
    vpc_key   = "raj-demo-vpc-2"
  }
}
