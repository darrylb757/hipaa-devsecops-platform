data "aws_caller_identity" "current" {}

locals {
  oidc_url = "https://token.actions.githubusercontent.com"

  # GitHub OIDC thumbprint (commonly used). If your org requires dynamic retrieval,
  # we can swap this to data "tls_certificate".
  github_thumbprint = "6938fd4d98bab03faadb97b34396831e3780aea1"

  repo_full = "${var.github_owner}/${var.github_repo}"

  # Allowed subjects for the role trust policy
  allowed_subs = concat(
    [for b in var.allowed_branches : "repo:${local.repo_full}:ref:refs/heads/${b}"],
    var.allow_pull_requests ? ["repo:${local.repo_full}:ref:refs/pull/*/merge"] : []
  )

  ecr_repo_arns = [
    for r in var.ecr_repo_names :
    "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${r}"
  ]
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = local.oidc_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [local.github_thumbprint]

  tags = var.tags
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.allowed_subs
    }
  }
}

resource "aws_iam_role" "gha" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

# Least-privilege ECR permissions for build/push/pull
data "aws_iam_policy_document" "ecr_access" {
  # Required to auth to ECR (resource must be "*")
  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Repository-scoped actions (push/pull)
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = local.ecr_repo_arns
  }

  # Optional: allow creating the repo if it doesn't exist (CreateRepository can't be resource-scoped well)
  statement {
    effect    = "Allow"
    actions   = ["ecr:CreateRepository"]
    resources = ["*"]
  }

  # Nice-to-have for debugging
  statement {
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_access" {
  name   = "${var.role_name}-ecr-access"
  policy = data.aws_iam_policy_document.ecr_access.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.gha.name
  policy_arn = aws_iam_policy.ecr_access.arn
}
