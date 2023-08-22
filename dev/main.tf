module "vpcmodule"{
    source = "../modules/vpc"
    vpc_cidr = var.dev_cidr
    public_subnet_one_cidr = var.dev_public_subnet_one
    public_subnet_two_cidr = var.dev_public_subnet_two
    public_subnet_three_cidr = null
    private_subnet_one_cidr = var.dev_private_subnet_one
    private_subnet_two_cidr = var.dev_private_subnet_two
    rivate_subnet_three_cidr = null
    env_name = var.dev_env_name
}