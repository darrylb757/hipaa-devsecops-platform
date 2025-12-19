variable "bucket_name" {
  description = "S3 bucket name for CI/CD artifacts"
  type        = string
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
