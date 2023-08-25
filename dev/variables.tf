variable "dev_cidr" {
    type = string 
    default = "10.10.0.0/16"
}    
variable "private_subnets" {
    default = ["10.10.3.0/24", "10.10.4.0/24"] 
}
variable "public_subnets" { 
    default = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "dev_env_name"   {
    type = string
    default = "DevEnv"
}
variable "project_code" {
    type = string
    default = "dm"
}
