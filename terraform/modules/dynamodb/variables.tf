variable "table_name" {
  type = string 
}

variable "hash_key" {
  type    = string
  default = "pk"
}

variable "kms_key_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
