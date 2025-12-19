resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.name}-subnet-group"
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "RDS access from EKS only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-sg"
  }
}

resource "aws_db_instance" "this" {
  identifier              = var.name
  engine                  = "postgres"
  instance_class          = var.instance_class
  allocated_storage       = 20
  max_allocated_storage   = 100

  db_name                 = var.db_name
  username                = var.username
  password                = var.password

  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.this.id]

  storage_encrypted       = true
  kms_key_id              = var.kms_key_id

  backup_retention_period = 7
  backup_window           = "03:00-04:00"

  multi_az                = false
  publicly_accessible     = false
  deletion_protection     = true

  skip_final_snapshot     = false
  final_snapshot_identifier = "${var.name}-final"

  tags = {
    Name        = var.name
    Environment = var.environment
  }
}
