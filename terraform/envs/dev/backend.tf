terraform {
  backend "s3" {
    bucket         = "hipaa-devsecops-tf-state-283993779348"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
    kms_key_id     = "alias/terraform-state"
  }
}
