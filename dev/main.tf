module "vpcmodule"{
    source = "../modules/vpc"

    cidr_vpc = var.dev_cidr
    private_subnets = var.private_subnets
    public_subnets = var.public_subnets
    env_name = var.dev_env_name
    project_code = var.project_code

    cluster_name    = var.cluster_name
    cluster_version = "1.24"
    subnet_ids      = var.private_subnets
    cluster_endpoint_public_access  = true

    cluster_addons = {
      coredns = {
        most_recent = true
      }
      kube-proxy = {
        most_recent = true
      }
      vpc-cni = {
        most_recent = true
      }
    }
    vpc_id = module.vpc_dev_test.vpc_id

    eks_managed_node_groups = {
        first = {
        desired_capacity = 1
        max_capacity     = 3
        min_capacity     = 1

        instance_type = "t2.micro"
        }
    }
}
