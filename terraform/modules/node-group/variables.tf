variable "name" {}
variable "env" {}
variable "cluster_name" {}
variable "subnet_ids" {
  type = list(string)
}
variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}
variable "desired_size" {
  default = 2
}
variable "min_size" {
  default = 1
}
variable "max_size" {
  default = 3
}
variable "tags" {
  type = map(string)
}
