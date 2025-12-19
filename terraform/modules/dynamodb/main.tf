resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = var.hash_key
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  lifecycle {
    ignore_changes = [
      server_side_encryption
    ]
  }

  tags = var.tags
}


