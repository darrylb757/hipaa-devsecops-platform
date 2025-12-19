variable "github_owner" {
  description = "GitHub org/user (e.g., darrylb757)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name (e.g., hipaa-devsecops-platform)"
  type        = string
}

variable "role_name" {
  description = "IAM role name for GitHub Actions OIDC"
  type        = string
  default     = "gha-oidc-ecr-role"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ecr_repo_names" {
  description = "List of ECR repositories this role can push/pull"
  type        = list(string)
  default     = ["patient-service"]
}

variable "allowed_branches" {
  description = "Branches allowed to assume the role (e.g., [\"main\"])"
  type        = list(string)
  default     = ["main"]
}

variable "allow_pull_requests" {
  description = "Allow PR workflows to assume the role (sub = refs/pull/*/merge)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
