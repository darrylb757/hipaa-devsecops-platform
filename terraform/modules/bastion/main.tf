############################
# Security Group
############################
resource "aws_security_group" "bastion" {
  name        = "${var.name}-${var.env}-bastion-sg"
  description = "Bastion SSH access"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from trusted IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

############################
# IAM Role for Bastion
############################
resource "aws_iam_role" "bastion" {
  name = "${var.name}-${var.env}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.name}-${var.env}-bastion-profile"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion_eks_describe" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::283993779348:policy/BastionEKSDescribeOnly"
}


resource "aws_iam_role_policy_attachment" "bastion_eks_cluster" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

############################
# Bastion EC2
############################
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-${var.env}-bastion"
  })
}

