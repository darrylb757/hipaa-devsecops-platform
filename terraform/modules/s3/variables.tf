variable "bucket_name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "noncurrent_expire_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}

