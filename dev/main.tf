module "vpcmodule"{
    source = "../modules/vpc"
    vpc_cidr = var.dev_cidr
    subnet_one_cidr = var.dev_subnet_one
    subnet_two_cidr = var.dev_subnet_two
    nat_gateway_one_cidr = var.decv_natgw_one
    env_name = var.dev_env_name
}