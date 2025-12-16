############################
# IAM Role for Nodes
############################
resource "aws_iam_role" "node_role" {
  name = "${var.name}-${var.env}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "worker_node" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

############################
# Managed Node Group
############################
resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.name}-${var.env}-ng"
  node_role_arn  = aws_iam_role.node_role.arn
  subnet_ids     = var.subnet_ids

  instance_types = var.instance_types

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  ami_type = "AL2_x86_64"

  disk_size = 50

  capacity_type = "ON_DEMAND"

  update_config {
    max_unavailable = 1
  }

  tags = merge(var.tags, {
    Name = "${var.name}-${var.env}-node"
  })
}
