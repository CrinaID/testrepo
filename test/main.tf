module "testmodule"{
    source = "../modules/vpc"
    cidr_vpc = var.test_cidr
    public_subnets = ["10.11.1.0/24", "10.11.2.0/24", "10.11.3.0/24"]
    private_subnets = ["10.11.4.0/24", "10.11.5.0/24, "10.11.6.0/24"] 
    env_name = var.test_env_name
}