


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
    private_subnet_one_id = module.vpcmodule.private_subnet_one_id
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
