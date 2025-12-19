variable "name" {}
variable "description" {}

variable "secret_string" {
  sensitive = true
}

variable "kms_key_id" {}

variable "tags" {
  type    = map(string)
  default = {}
}
