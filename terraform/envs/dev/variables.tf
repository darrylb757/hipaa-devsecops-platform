variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  description = "Project name"
  type        = string
  default     = "hipaa-devsecops"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    Project     = "hipaa-devsecops"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
