variable "cidr_vpc" {
  type = string
  default = "10.1.0.0/16"
}
variable "public_subnets" {}
variable "private_subnets" {}
variable "publicsub" {
    default = output.publicsubnets[0]
}
variable "env_name"{}