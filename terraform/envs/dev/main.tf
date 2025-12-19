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

data "aws_caller_identity" "current" {}


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

module "rds" {
  source = "../../modules/rds"

  name        = "hipaa-devsecops-db"
  environment = var.env

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [
    module.eks.cluster_primary_security_group_id
  ]

  db_name  = "appdb"
  username = "appuser"
  password = var.rds_password

  kms_key_id = data.aws_kms_key.rds.arn
}

data "aws_kms_key" "rds" {
  key_id = "alias/aws/rds"
}

data "aws_kms_key" "s3" { key_id = "alias/aws/s3" }
data "aws_kms_key" "dynamodb" { key_id = "alias/aws/dynamodb" }

module "s3_data" {
  source = "../../modules/s3"

  bucket_name            = "hipaa-devsecops-${var.env}-data-${data.aws_caller_identity.current.account_id}"
  kms_key_arn            = data.aws_kms_key.s3.arn
  noncurrent_expire_days = 30

  tags = {
    Project     = "hipaa-devsecops-platform"
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

module "dynamodb_app" {
  source = "../../modules/dynamodb"

  table_name  = "hipaa-devsecops-${var.env}-app"
  hash_key    = "pk"
  kms_key_arn = data.aws_kms_key.dynamodb.arn

  tags = {
    Project     = "hipaa-devsecops-platform"
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

module "kms_data" {
  source = "../../modules/kms"

  name        = "hipaa-devsecops-data"
  description = "KMS key for application data (RDS, DynamoDB, S3)"

  tags = {
    Project = "hipaa-devsecops-platform"
    Env     = var.env
    Purpose = "data-encryption"
  }
}

module "kms_secrets" {
  source = "../../modules/kms"

  name        = "hipaa-devsecops-secrets"
  description = "KMS key for Secrets Manager"

  tags = {
    Project = "hipaa-devsecops-platform"
    Env     = var.env
    Purpose = "secrets-encryption"
  }
}

module "kms_logs" {
  source = "../../modules/kms"

  name        = "hipaa-devsecops-logs"
  description = "KMS key for CloudWatch logs"

  tags = {
    Project = "hipaa-devsecops-platform"
    Env     = var.env
    Purpose = "logs-encryption"
  }
}

module "app_secrets" {
  source = "../../modules/secrets-manager"

  name        = "hipaa-devsecops-dev-app"
  description = "Application secrets for dev"

  secret_string = jsonencode({
    DB_USER = "appuser"
    DB_NAME = "appdb"
  })

  kms_key_id = module.kms_secrets.key_arn


  tags = {
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_policy" "app_secrets_policy" {
  name = "hipaa-devsecops-dev-secrets-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = module.app_secrets.secret_arn
    }]
  })
}

resource "aws_iam_policy" "eso_secrets_read" {
  name = "hipaa-devsecops-eso-secrets-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Secrets Manager access
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      },

      # KMS decrypt permission for Secrets Manager CMK
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = module.kms_secrets.key_arn
      }
    ]
  })
}



module "app_irsa" {
  source = "../../modules/irsa"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn

  namespace            = "default"
  service_account_name = "app-sa"

  role_name = "dev-app-irsa-role"

  policy_arns = [
    aws_iam_policy.app_secrets_policy.arn,
    aws_iam_policy.app_kms_decrypt_policy.arn
  ]
}

resource "aws_iam_policy" "app_kms_decrypt_policy" {
  name = "hipaa-devsecops-dev-kms-decrypt"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = module.kms_secrets.key_arn
      }
    ]
  })
}

module "observability" {
  source = "../../modules/observability"

  cluster_name = module.eks.cluster_name
  env          = var.env
  kms_key_arn  = module.kms_logs.key_arn

  # keep alarms off until we confirm metric names/dimensions (safe)
  enable_containerinsights_alarms = false

  # optional
  enable_email_alerts = false
  alert_email         = ""

  tags = {
    Project = "hipaa-devsecops-platform"
    Env     = var.env
  }
}

module "external_secrets_irsa" {
  source = "../../modules/irsa"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn

  namespace            = "external-secrets"
  service_account_name = "external-secrets"

  role_name = "dev-external-secrets-irsa-role"

  policy_arns = [
    aws_iam_policy.eso_secrets_read.arn
  ]
}

module "artifact_bucket" {
  source      = "../../modules/s3-artifacts"
  bucket_name = "hipaa-devsecops-artifacts-283993779348"
  tags = {
    Environment = "dev"
    Project     = "hipaa-devsecops-platform"
    Owner       = "darryl-b"
    Purpose     = "cicd-artifacts"
  }
}

module "github_oidc" {
  source = "../../modules/iam-github-oidc"

  github_owner = "darrylb757"
  github_repo  = "hipaa-devsecops-platform"

  role_name           = "gha-oidc-ecr-role"
  aws_region          = "us-east-1"
  ecr_repo_names      = ["patient-service"]
  allowed_branches    = ["main"]
  allow_pull_requests = true

  tags = {
    Environment = "dev"
    Project     = "hipaa-devsecops-platform"
    Purpose     = "github-actions-oidc"
  }
}
