variable "cidr_vpc" {
  type = string
  default = "10.1.0.0/16"
}
variable "public_subnet_one_cidr" {}
variable "public_subnet_two_cidr" {}
variable "private_subnet_one_cidr" {}
variable "private_subnet_two_cidr" {}


variable "env_name"{}