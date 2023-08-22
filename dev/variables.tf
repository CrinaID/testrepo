variable "dev_cidr" {
    type = string 
    default = "10.0.0.0/16"
}
variable "dev_public_subnet_one" {
    type = string
    default = "10.10.1.0/24"
}
variable "dev_public_subnet_two" {
    type = string
    default = "10.10.2.0/24"
}
variable "dev_private_subnet_one" {
    type = string
    default = "10.10.3.0/24"
}
variable "dev_private_subnet_two" {
    type = string
    default = "10.10.4.0/24"
}
variable "dev_env_name"   {
    type = string
    default = "DevEnv"
}