module "vpcmodule"{
    source = "../modules/vpc"

    cidr_vpc = var.dev_cidr
    private_subnets = var.private_subnets
    output "publicsubnets"{
    value = var.public_subnets[0].id
    } 
    public_subnets = var.public_subnets
    env_name = var.dev_env_name
}