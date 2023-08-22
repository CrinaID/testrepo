module "vpcmodule"{
    source = "../modules/vpc"
    cidr_vpc = var.test_cidr
    public_subnet_one_cidr = var.test_public_subnet_one
    public_subnet_two_cidr = var.test_public_subnet_two
    public_subnet_three_cidr = var.test_public_subnet_three
    private_subnet_one_cidr = var.test_private_subnet_one
    private_subnet_two_cidr = var.test_private_subnet_two
    private_subnet_three_cidr = var.test_private_subnet_three
    env_name = var.test_env_name
}