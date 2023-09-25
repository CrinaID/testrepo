provider "aws" {
  region = var.region
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
    "kubernetes.io/role/elb"           = "1"
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
//so that private subnets can access the internet, redirect through NAT gateway

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc_dm_eks.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_one.id
  }

  tags = {
    Name = "private"
  }
}
resource "aws_route_table_association" "private-subnet-1" {
  subnet_id      = aws_subnet.private_subnets[0].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-subnet-2" {
  subnet_id      = aws_subnet.private_subnets[1].id
  route_table_id = aws_route_table.private.id
}
//associate the public subnets to the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc_dm_eks.id

  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "public"
  }
}
resource "aws_route_table_association" "public-subnet-1" {
  subnet_id      = aws_subnet.public_subnets[0].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-subnet-2" {
  subnet_id      = aws_subnet.public_subnets[1].id
  route_table_id = aws_route_table.public.id
}

//Create Elastic IP for the NAT Gateway
resource "aws_eip" "Nat-Gateway-EIP" {
  depends_on = [
    aws_route_table_association.public-subnet-1
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





data "tls_certificate" "eks" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

//eks service account
data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role_policy" {
  statement{
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

  condition {
    test     = "StringEquals"
    variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
    values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
  }

  principals {
    identifiers = [aws_iam_openid_connect_provider.eks.arn]
    type        = "Federated"
  }
  }
}
#should have env specified
resource "aws_iam_role" "aws_load_balancer_controller" {
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy.json
  name               = "aws-load-balancer-controller-${var.env_name}"
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  policy = file("${path.module}/LBControllerTF.json")
  name   = "LBControllerTF-${var.env_name}"
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}


resource "helm_release" "aws-load-balancer-controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version = "1.4.1"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.cluster.id
  }
  set {
    name = "image.repository"
    value = "public.ecr.aws/eks/aws-load-balancer-controller"
  }
  /*set {
    name  = "image.tag"
    value = "v2.3.0"
  }*/

  set {
    name  = "replicaCount"
    value = 1
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  # EKS Fargate specific
  set {
    name  = "region"
    value = "eu-north-1"
  }

  set {
    name  = "vpcId"
    value = aws_vpc.vpc_dm_eks.id
  }

  depends_on = [aws_eks_fargate_profile.kube-system]
}

resource "aws_efs_file_system" "eks" {
  creation_token = "eks"

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  # lifecycle_policy {
  #   transition_to_ia = "AFTER_30_DAYS"
  # }

  tags = {
    Name = "dm-eks-filesystem"
  }
}

resource "aws_efs_mount_target" "zone-a" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = aws_subnet.private_subnets[0].id
  security_groups = [aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id]
}

resource "aws_efs_mount_target" "zone-b" {
  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = aws_subnet.private_subnets[1].id
  security_groups = [aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id]
}

#####################################################################################


// EXTERNAL SECRETS


#####################################################################################

resource "aws_eks_fargate_profile" "externalsecrets" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "frontend"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile.arn

  # These subnets must have the following resource tag: 
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = [
    aws_subnet.private_subnets[0].id,
    aws_subnet.private_subnets[1].id
  ]

  selector {
    namespace = "frontend"
  }
}
# Policy
data "aws_iam_policy_document" "external_secrets" {
  count = var.enabled ? 1 : 0
  statement {
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "ssm:GetParameter*"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

}

resource "aws_iam_policy" "external_secrets" {
  depends_on  = [var.mod_dependency]
  count       = var.enabled ? 1 : 0
  name        = "${var.cluster_name}-external-secrets"
  path        = "/"
  description = "Policy for external secrets service"

  policy = data.aws_iam_policy_document.external_secrets[0].json
}

# Role
data "aws_iam_policy_document" "external_secrets_assume" {
  count = var.enabled ? 1 : 0
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"

      values = [
        "system:serviceaccount::${var.namespace}:${var.service_account_name}",
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "external_secrets" {
  count              = var.enabled ? 1 : 0
  name               = "${var.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume[0].json
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  count      = var.enabled ? 1 : 0
  role       = aws_iam_role.external_secrets[0].name
  policy_arn = aws_iam_policy.external_secrets[0].arn
}

module "eks-irsa" {
  source  = "nalbam/eks-irsa/aws"
  version = "0.13.2"

  name = "apps_role_${var.env_name}"
  region = var.region
  cluster_name = aws_eks_cluster.cluster.name
  cluster_names = [
    aws_eks_cluster.cluster.name
  ]
  kube_namespace      = "${var.namespace}"
  kube_serviceaccount = "${var.service_account_name}"

  policy_arns = [
    aws_iam_policy.iamSecretPolicy.arn
  ]

  depends_on = [
    aws_eks_cluster.cluster
  ]
}

resource "aws_iam_policy" "iamSecretPolicy" {
  name        = "${var.env_name}_secretPolicy"
  path        = "/"
  description = "Allow access to ${var.env_name} secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:secretsmanager:${var.region}:855859226163:secret:${var.env_name}/*"
        ]
      },
    ]
  })
}

resource "helm_release" "external-secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  verify     = "false"
  namespace  = "frontend"
  create_namespace = true
  values = [
    templatefile("${path.module}/helm/kubernetes-external-secrets/values.yml", { roleArn = "${module.eks-irsa.arn}" })
  ]
  set {
    name  = "createCRD"
    value = "true"
  }
  set {
    name  = "metrics.enabled"
    value = "true"
  }

  set {
    name  = "service.annotations.prometheus\\.io/port"
    value = "9127"
    type  = "string"
  }
}