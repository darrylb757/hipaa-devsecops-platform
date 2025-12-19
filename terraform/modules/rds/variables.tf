variable "name" {}
variable "environment" {}

variable "vpc_id" {}
variable "private_subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_ids" {
  type = list(string)
}

variable "instance_class" {
  default = "db.t3.micro"
}

variable "db_name" {}
variable "username" {}
variable "password" {
  sensitive = true
}

variable "kms_key_id" {}
