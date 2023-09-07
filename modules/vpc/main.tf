provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "dm-gen-configuration"
    key    = "/"
    region = "eu-west-1"
  }
}

resource "aws_vpc" "vpc_dm_eks" {
  cidr_block = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support = true
  tags      = {
    Name    = "${var.project_code}-${var.env_name}-vpc"
  }
}

data "aws_availability_zones" "available" {}

// What if the number of subnets differs from the number of availability zones?
// Code needs to be refactored/improved for private and public subnet resources!
resource "aws_subnet" "public_subnets" {
  count = "${length(var.public_subnets)}"

  cidr_block = var.public_subnets[count.index]
  availability_zone= "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id   = aws_vpc.vpc_dm_eks.id
  tags = {
    
    Name = "${var.project_code}-${var.env_name}-publicsub-${1+count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/role/elb"= "1"
  }
}

resource "aws_subnet" "private_subnets" {
  
  count = "${length(var.private_subnets)}"
  cidr_block = var.private_subnets[count.index]
  availability_zone= "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id   = aws_vpc.vpc_dm_eks.id
  tags = {
    Name = "${var.project_code}-${var.env_name}-privatesub-${1+count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/role/elb"= "1"
  }
}

//Create an Internet Gateway 
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc_dm_eks.id
  tags = {
    "Name" = "${var.project_code}-${var.env_name}-igw"
  }
}
//create route table for the Internet Gateway
resource "aws_route_table" "internet_gateway_rt" {
  vpc_id = aws_vpc.vpc_dm_eks.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    "Name" = "${var.project_code}-${var.env_name}-routetbl"
  }
  
}
//associate the IGW to the first public subnet
resource "aws_route_table_association" "nat_gateway_one_rt" {
  subnet_id = aws_subnet.public_subnets[0].id
  route_table_id = aws_route_table.internet_gateway_rt.id

}
//Create Elastic IP for the NAT Gateway
resource "aws_eip" "Nat-Gateway-EIP" {
  depends_on = [
    aws_route_table_association. nat_gateway_one_rt
  ]
  vpc = true
  tags = {
    "Name" = "${var.project_code}-${var.env_name}-ElasticIP"
  
  }
}

resource "aws_nat_gateway" "nat_gateway_one" {
  depends_on = [
    aws_eip.Nat-Gateway-EIP,
    aws_internet_gateway.internet_gateway
  ]
 
  # Allocating the Elastic IP to the NAT Gateway!
  allocation_id = aws_eip.Nat-Gateway-EIP.id
  
  # Associating it in the Public Subnet!
  subnet_id = aws_subnet.public_subnets[0].id
  tags = {
    Name = "${var.project_code}-${var.env_name}-NAT"
  
  }
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids = concat(var.public_subnets.*.id, var.private_subnets.*.id)
  }

  timeouts {
    delete = "30m"
  }

  depends_on = [
    aws_cloudwatch_log_group.eks_cluster,
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy
  ]
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.10"
}

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.main.id
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.main.id
}

resource "aws_iam_policy" "AmazonEKSClusterCloudWatchMetricsPolicy" {
  name   = "AmazonEKSClusterCloudWatchMetricsPolicy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}


resource "aws_iam_role" "eks_cluster_role" {
  name                  = "${var.project_code}-eks-${var.env_name}-cluster-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSCloudWatchMetricsPolicy" {
  policy_arn = aws_iam_policy.AmazonEKSClusterCloudWatchMetricsPolicy.arn
  role       = aws_iam_role.eks_cluster_role.name
}


resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 30

  tags = {
    Name        = "${var.env_name}-eks-cloudwatch-log-group"
    Environment = var.env_name
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "kube-system"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.private_subnets.*.id

  scaling_config {
    desired_size = 4
    max_size     = 4
    min_size     = 4
  }

  instance_types  = ["t2.micro"]

  tags = {
    Name        = "dm-eks-${var.env_name}-node-group"

  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "eks_node_group_role" {
  name                  = "dm-eks-node-group-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

data "template_file" "kubeconfig" {
  template = file("${path.module}/templates/kubeconfig.tpl")

  vars = {
    kubeconfig_name           = "eks_${aws_eks_cluster.main.name}"
    clustername               = aws_eks_cluster.main.name
    endpoint                  = data.aws_eks_cluster.cluster.endpoint
    cluster_auth_base64       = data.aws_eks_cluster.cluster.certificate_authority[0].data
  }
}

resource "local_file" "kubeconfig" {
  content  = data.template_file.kubeconfig.rendered
  filename = pathexpand("~/.kube/config")
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.external.thumbprint.result.thumbprint]
  url             = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}
data "external" "thumbprint" {
  program =    ["${path.module}/oidc_thumbprint.sh", var.region]
  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_fargate_profile" "main" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "fp-default"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = var.private_subnets.*.id

  selector {
    namespace = "default"
  }

  selector {
    namespace = "2048-game"
  }
}
resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

resource "aws_iam_role" "fargate_pod_execution_role" {
  name                  = "dm-eks-fargate-pod-execution-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}