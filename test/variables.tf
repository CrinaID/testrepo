variable "test_cidr" {
    type = string 
    default = "10.11.0.0/16"
}
variable "test_subnet_one" {
    type = string
    default = "10.11.0.0/24"
}
variable "test_subnet_two" {
    type = string
    default = "10.11.0.128/24"
}
variable "test_natgw_one"  {
     type = string
    default = "10.11.0.0/24"
}
variable "test_env_name"   {
    type = string
    default = "Test_Environment_VPC"
}
