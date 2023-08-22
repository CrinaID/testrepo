module "vpcmodule"{
    source = "../modules/vpc"
    cidr_vpc = var.dev_cidr
    public_subnet_one_cidr = var.dev_public_subnet_one
    public_subnet_two_cidr = var.dev_public_subnet_two
    public_subnet_three_cidr = null
    private_subnet_one_cidr = var.dev_private_subnet_one
    private_subnet_two_cidr = var.dev_private_subnet_two
    private_subnet_three_cidr = null
    env_name = var.dev_env_name
}