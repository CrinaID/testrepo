module "vpcmodule"{
    source = "../modules/vpc"
    cidr_vpc = var.test_cidr
    subnet_one_cidr = var.test_subnet_one
    subnet_two_cidr = var.test_subnet_two
    nat_gateway_one_cidr = var.test_natgw_one
    env_name = var.test_env_name
}