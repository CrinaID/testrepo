module "vpcmodule"{
    source = "../modules/vpc"

    cidr_vpc = var.dev_cidr
   
    env_name = var.dev_env_name
}