module "vpcmodule"{
    source = "../modules/vpc"

    cidr_vpc = var.dev_cidr
    private_subnets = var.private_subnets
    publicsub = output.publicsubnets[0]
    public_subnets = var.public_subnets
    env_name = var.dev_env_name
}