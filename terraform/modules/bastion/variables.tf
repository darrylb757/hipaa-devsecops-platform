variable "name" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "allowed_ssh_cidr" {
  type = string
  description = "Your public IP /32"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "tags" {
  type    = map(string)
  default = {}
}
