var "test_cidr" {
    type = string 
    default = "10.11.0.0/16"
}
var "test_subnet_one" {
    type = string
    default = "10.11.0.0/24"
}
var "test_subnet_two" {
    type = string
    default = "10.11.0.128/24"
}
var "test_natgw_one"  {
     type = string
    default = "10.11.0.0/24"
}
var "test_env_name"   {
    type = string
    default = "Test_Environment_VPC"
}
