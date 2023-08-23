variable "cidr_vpc" {
  type = string
  default = "10.1.0.0/16"
}
private_subnet = []
public_subnets= []

variable "env_name"{}