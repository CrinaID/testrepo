


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
module "dynamodb" {
    source = "../modules/dynamodb"
    env_name = var.dev_env_name
}
module "eks_cluster"{
    source = "../modules/eks"
    cluster_name = var.cluster_name
    cluster_version = var.cluster_version
    private_subnets_ids = module.vpcmodule.private_subnets_output.*.id
    public_subnets_ids = module.vpcmodule.public_subnets_output.*.id

}
module "load_balancer" {
    source = "../modules/load-balancer"
    vpc_id = module.vpcmodule.vpc.id
    eks_cluster = module.eks_cluster.eks_cluster
    env_name = var.dev_env_name
    eks_fargate_profile_kubesystem = module.eks_cluster.eks_fargate_profile_kubesystem
}
module "external_secrets"{
    source = "../modules/external-secrets"
    eks_cluster = module.eks_cluster.eks_cluster
    cluster_name = var.cluster_name
    iam_fargate = module.eks_cluster.iam_fargate
    openid_connector = module.load_balancer.openid_connector
    env_name = var.dev_env_name
    region = var.region
    private_subnet_one_id = module.vpcmodule.private_subnets_output[0].id
    private_subnet_two_id = module.vpcmodule.private_subnets_output[1].id
}

module "efs" {
    source = "../modules/efs"
    private_subnet_one_id = module.vpcmodule.private_subnets_output[0].id
    private_subnet_two_id = module.vpcmodule.private_subnets_output[1].id
    eks_cluster = module.eks_cluster.eks_cluster
}

module "app_params" {
    source  = "../modules/parameter-store"
    prefix = "/dm/dev/data-marketplace/gen/"
    securestring_parameters = [
        "API_ENDPOINT",
        "SSO_AUTH_URL",
        "SSO_CALLBACK_URL",
        "SSO_CLIENT_ID",
        "SSO_CLIENT_SECRET",
        "JWT_AUD",
        "JWKS_URL"
    ]
}
