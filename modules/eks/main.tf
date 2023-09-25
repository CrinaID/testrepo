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