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

  name     = "hipaa-devsecops"
  env      = var.env
  region   = var.region
  vpc_cidr = "10.0.0.0/16"
  az_count = 3

  # Dev: cheaper (1 NAT). Later we’ll set false for stage/prod.
  single_nat_gateway = true

  tags = {
    Project = "hipaa-devsecops-platform"
    Env     = var.env
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = "hipaa-devsecops-eks"
  env                = var.env
  region             = var.region
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  tags = {
    Project = "hipaa-devsecops-platform"
    Env     = var.env
  }
}

module "bastion" {
  source = "../../modules/bastion"

  name             = "hipaa-devsecops"
  env              = var.env
  vpc_id           = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnet_ids[0]

  # Replace with MY public IP /32
  allowed_ssh_cidr = "76.195.46.228/32"

  tags = {
    Project = "hipaa-devsecops-platform"
    Env     = var.env
  }
}

module "node_group" {
  source = "../../modules/node-group"

  name         = var.name
  env          = var.env
  cluster_name = module.eks.cluster_name

  subnet_ids = module.vpc.private_subnet_ids

  instance_types = ["t3.medium"]
  desired_size   = 2
  min_size       = 1
  max_size       = 3

  tags = var.tags
}
