


module "vpcmodule"{
    source = "../modules/vpc"

    cidr_vpc = var.vpc_cidr
    private_subnets = var.private_subnets
    public_subnets = var.public_subnets
    env_name = var.dev_env_name
    project_code = var.project_code

    cluster_name = var.cluster_name
    cluster_version = var.cluster_version
    region = var.region
}
module "efsmodule" {
    source = "../modules/efs"
    env_name = var.dev_env_name
    project_code = var.project_code

}
