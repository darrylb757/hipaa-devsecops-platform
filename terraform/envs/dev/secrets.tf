resource "aws_secretsmanager_secret" "rds" {
  name = "dev/rds/postgres"
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id

  secret_string = jsonencode({
    username = "appuser"
    password = var.rds_password
  })
}
