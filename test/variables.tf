variable "test_cidr" {
    type = string 
    default = "10.11.0.0/16"
}
variable "test_public_subnet_one" {
    type = string
    default = "10.11.0.0/24"
}
variable "test_public_subnet_two" {
    type = string
    default = "10.11.1.0/24"
}
variable "test_public_subnet_three" {
    type = string
    default = "10.11.2.0/24"
}
variable "test_private_subnet_one" {
    type = string
    default = "10.11.3.0/24"
}
variable "test_private_subnet_two" {
    type = string
    default = "10.11.4.0/24"
}
variable "test_private_subnet_three" {
    type = string
    default = "10.11.5.0/24"
}

variable "test_env_name"   {
    type = string
    default = "TestEnv"
}
