variable "test_cidr" {
    type = string 
    default = "10.11.0.0/16"
}
variable "test_public_subnet_one" {
    type = string
    default = "172.16.0.0/12"
}
variable "test_public_subnet_two" {
    type = string
    default = "172.16.1.0/12"
}
variable "test_private_subnet_one" {
    type = string
    default = "10.11.0.0/24"
}
variable "test_private_subnet_two" {
    type = string
    default = "10.11.1.0/24"
}

variable "test_env_name"   {
    type = string
    default = "TestEnv"
}
