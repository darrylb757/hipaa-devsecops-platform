terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.25"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = "hipaa-devsecops-platform"
      Owner   = "DarrylBrown"
      Env     = var.env
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name               = "hipaa-devsecops"
  env                = var.env
  region             = var.region
  vpc_cidr            = "10.0.0.0/16"
  az_count            = 3

  # Dev: cheaper (1 NAT). Later we’ll set false for stage/prod.
  single_nat_gateway = true

  tags = {
    Project = "hipaa-devsecops-platform"
    Env     = var.env
  }
}
