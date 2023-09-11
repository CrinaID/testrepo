
module "vpcmodule"{
    source = "../modules/vpc"
    cidr_vpc = var.test_cidr
    public_subnets = var.public_subnets
    private_subnets = var.private_subnets
    env_name = var.test_env_name
    project_code = var.project_code
    cluster_name = var.cluster_name
    cluster_version = var.cluster_version
}