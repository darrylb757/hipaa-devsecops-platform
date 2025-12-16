variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "region" {
  type        = string
}

variable "vpc_id" {
  type        = string
}

variable "private_subnet_ids" {
  type        = list(string)
}

variable "env" {
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
}
