var "dev_cidr" {
    type = string 
    default = "10.0.0.0/16"
}
var "dev_subnet_one" {
    type = string
    default = "10.10.0.0/24"
}
var "dev_subnet_two" {
    type = string
    default = "10.10.0.128/24"
}
var "dev_natgw_one"  {
     type = string
    default = "10.10.0.0/24"
}
var "dev_env_name"   {
    type = string
    default = "Dev_Environment_VPC"
}