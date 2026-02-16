terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.20"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# --- Default provider (eu-central-1) ---

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project       = "UAI3"
      Environment   = "Lab"
      ManagedBy     = "Terraform"
      ResourceOwner = var.resource_owner
    }
  }
}

# --- Regional provider aliases ---

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project       = "UAI3"
      Environment   = "Lab"
      ManagedBy     = "Terraform"
      ResourceOwner = var.resource_owner
    }
  }
}

provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"

  default_tags {
    tags = {
      Project       = "UAI3"
      Environment   = "Lab"
      ManagedBy     = "Terraform"
      ResourceOwner = var.resource_owner
    }
  }
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"

  default_tags {
    tags = {
      Project       = "UAI3"
      Environment   = "Lab"
      ManagedBy     = "Terraform"
      ResourceOwner = var.resource_owner
    }
  }
}

provider "aws" {
  alias  = "ap_northeast_1"
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Project       = "UAI3"
      Environment   = "Lab"
      ManagedBy     = "Terraform"
      ResourceOwner = var.resource_owner
    }
  }
}

provider "aws" {
  alias  = "sa_east_1"
  region = "sa-east-1"

  default_tags {
    tags = {
      Project       = "UAI3"
      Environment   = "Lab"
      ManagedBy     = "Terraform"
      ResourceOwner = var.resource_owner
    }
  }
}

provider "aws" {
  alias  = "ca_central_1"
  region = "ca-central-1"

  default_tags {
    tags = {
      Project       = "UAI3"
      Environment   = "Lab"
      ManagedBy     = "Terraform"
      ResourceOwner = var.resource_owner
    }
  }
}

provider "aws" {
  alias  = "ap_south_1"
  region = "ap-south-1"

  default_tags {
    tags = {
      Project       = "UAI3"
      Environment   = "Lab"
      ManagedBy     = "Terraform"
      ResourceOwner = var.resource_owner
    }
  }
}
