provider "aws" {
  region = var.region
}

resource "aws_kms_key" "state_backend_bucket_kms_key" {
  description             = "Encrypt the state bucket objects"
  deletion_window_in_days = 10
}
resource "aws_s3_bucket" "state_backend_bucket" {
  bucket = "dm-gen-configuration"

}
resource "aws_s3_bucket_versioning" "state_backend_bucket_versioning" {
  bucket  = aws_s3_bucket.state_backend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "state_backend_bucket_encryption" {
  bucket = aws_s3_bucket.state_backend_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state_backend_bucket_kms_key.arn
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# block S3 bucket public access per each Env's bucket
resource "aws_s3_bucket_public_access_block" "state_backend_bucket_acl" {
  bucket = aws_s3_bucket.state_backend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# create DynamoDB table per each Env
resource "aws_dynamodb_table" "state_dynamo_table" {
  name = "tf-state-lock-${var.env_name}"

  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
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



//IAM role for EKS - used to make API calls to AWS services
//i.e. to create managed node pools


resource "aws_iam_role" "eks-cluster" {
  name = "eks-cluster-${var.cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

// Attach AmazonEKSClusterPolicy

resource "aws_iam_role_policy_attachment" "amazon-eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster.name
}

//EKS cluster

resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks-cluster.arn
  //count = "${length(aws_subnet.private_subnets)}"

  /*enable_cluster_autoscaler = true
  enable_aws_load_balancer_controller   = true
  enable_metrics_server = true

   metrics_server_helm_config = {
    values = [templatefile("${path.module}/k8s/metrics-server-values.yaml", {
      operating_system = "linux"
    })]
  }*/
  vpc_config {

    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    //need to improve this code and not use 0 and 1 
    subnet_ids = [
        aws_subnet.private_subnets[0].id,
        aws_subnet.public_subnets[0].id,
        aws_subnet.private_subnets[1].id,
        aws_subnet.public_subnets[1].id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.amazon-eks-cluster-policy]
}


resource "aws_iam_role" "eks-fargate-profile" {
  name = "eks-fargate-profile"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
    
  })
}


resource "aws_iam_role_policy_attachment" "eks-fargate-profile" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks-fargate-profile.name
}


resource "aws_eks_fargate_profile" "kube-system" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile.arn

  //count = "${length(aws_subnet.private_subnets)}"
  subnet_ids = [
    aws_subnet.private_subnets[0].id,
    aws_subnet.private_subnets[1].id
  ]

  selector {
    namespace = "kube-system"
  }
}

resource "aws_eks_fargate_profile" "staging" {
  cluster_name           = aws_eks_cluster.cluster.name
  fargate_profile_name   = "staging"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile.arn

  # These subnets must have the following resource tag: 
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = [
    aws_subnet.private_subnets[0].id,
    aws_subnet.private_subnets[1].id
  ]

  selector {
    namespace = "staging"
  }
}
//remove ec2 annotation from CoreDNS deployment

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.cluster.id
}

resource "null_resource" "k8s_patcher" {
  depends_on = [aws_eks_fargate_profile.kube-system]

  triggers = {
    endpoint = aws_eks_cluster.cluster.endpoint
    ca_crt   = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
    token    = data.aws_eks_cluster_auth.eks.token
  }

  provisioner "local-exec" {
    command = <<EOH
cat >/tmp/ca.crt <<EOF
${base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)}
EOF
kubectl \
  --server="${aws_eks_cluster.cluster.endpoint}" \
  --certificate_authority=/tmp/ca.crt \
  --token="${data.aws_eks_cluster_auth.eks.token}" \
  patch deployment coredns \
  -n kube-system --type json \
  -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
EOH
  }

  lifecycle {
    ignore_changes = [triggers]
  }
}


provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"

      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.cluster.id]
      command     = "aws"
    }   
  }
}
/*
resource "helm_release" "metrics-server" {
    name = "metrics-server"

    repository       = "https://charts.bitnami.com/bitnami"
    chart            = "metrics-server"
    namespace        = "metrics-server"
    //version          = "5.11.1"
    create_namespace = true

    set {
        name  = "apiService.create"
        value = "true"
    }

  depends_on = [aws_eks_fargate_profile.kube-system]
}
*/

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

resource "aws_iam_role" "aws_load_balancer_controller" {
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy.json
  name               = "aws-load-balancer-controller"
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  policy = file("${path.module}/LBControllerTF.json")
  name   = "LBControllerTF"
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

