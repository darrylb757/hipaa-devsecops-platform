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
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

########################
# KMS for TF state
########################
resource "aws_kms_key" "tf_state" {
  description             = "KMS key for Terraform remote state encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  # Optional but recommended: a tighter key policy baseline
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow account root full control (standard baseline)
      {
        Sid      = "AllowAccountRoot"
        Effect   = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "tf_state" {
  name          = "alias/terraform-state"
  target_key_id = aws_kms_key.tf_state.key_id
}

########################
# S3 bucket for TF state
########################
resource "aws_s3_bucket" "tf_state" {
  bucket = "hipaa-devsecops-tf-state-283993779348"

  lifecycle {
    prevent_destroy = true
  }
}

# Enforce bucket ownership controls (disables ACL-based ownership confusion)
resource "aws_s3_bucket_ownership_controls" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Good practice: explicitly block ACLs at the bucket level
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning for recovery/rollback
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Default encryption with SSE-KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tf_state.arn
    }
  }
}

# Optional but recommended: extra safety against accidental deletion
resource "aws_s3_bucket_lifecycle_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

########################
# Bucket policy hardening
########################
data "aws_iam_policy_document" "tf_state_bucket_policy" {
  # Deny non-HTTPS access
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.tf_state.arn,
      "${aws_s3_bucket.tf_state.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Deny objects that are not encrypted with SSE-KMS
  statement {
    sid     = "DenyIncorrectEncryptionHeader"
    effect  = "Deny"
    actions = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.tf_state.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  # Deny objects that do not specify the correct KMS key
  statement {
    sid     = "DenyWrongKMSKey"
    effect  = "Deny"
    actions = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.tf_state.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.tf_state.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  policy = data.aws_iam_policy_document.tf_state_bucket_policy.json

  depends_on = [
    aws_s3_bucket_public_access_block.tf_state,
    aws_s3_bucket_ownership_controls.tf_state
  ]
}

########################
# DynamoDB state lock table
########################
resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }
}
