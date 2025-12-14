variable "name" {
  type        = string
  description = "Name prefix for VPC resources"
}

variable "env" {
  type        = string
  description = "Environment name (dev/stage/prod)"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "az_count" {
  type        = number
  description = "Number of AZs to use"
  default     = 3
}

variable "single_nat_gateway" {
  type        = bool
  description = "If true, create only 1 NAT gateway (cheaper, good for dev). If false, NAT per AZ (more HA)."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}
