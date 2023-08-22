variable "cidr_vpc" {
  type = string
  default = "10.1.0.0/16"
}
variable "subnet_one_cidr" {}
variable "subnet_two_cidr" {}
variable "nat_gateway_one_cidr" {}
variable "nat_gateway_cidr" {}
//variable "route_table_one_cidr" {}
//variable "route_table_two_cidr" {}

variable "env_name"{}