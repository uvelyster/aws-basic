provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_eks_cluster" "my-cluster" {
  name     = "my-cluster"
  role_arn = aws_iam_role.my_cluster_role.arn

  vpc_config {
    subnet_ids = ["subnet-07dad591b164ef9fe", "subnet-09d8ead975598f7e9"]
  }
}

resource "aws_iam_role" "my_cluster_role" {
  name = "my-cluster-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "my_cluster_policy_attachment" {
  name       = "AmazonEKSClusterPolicy"
  roles      = [aws_iam_role.my_cluster_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_policy_attachment" "my_node_policy_attachment" {
  name       = "AmazonEKSWorkerNodePolicy"
  roles      = [aws_iam_role.my_cluster_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_policy_attachment" "my_cni_policy_attachment" {
  name       = "AmazonEKSVPCResourceController"
  roles      = [aws_iam_role.my_cluster_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.my-cluster.name
  node_group_name = "my-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 4
  }

  subnet_ids = ["subnet-09d8ead975598f7e9", "subnet-07dad591b164ef9fe"]
  instance_types = ["t3.medium"]
  ami_type = "AL2_x86_64"
  disk_size = 20
  tags = {
    Environment = "test",
    Project     = "cj-project"
  }
}

resource "aws_iam_role" "eks_node_role" {
  name               = "eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_registry_readonly_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_iam_role_policy_attachment" "eks_node_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}


resource "aws_iam_role_policy_attachment" "eks_cni_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

output "eks_cluster_name" {
  value = aws_eks_cluster.my-cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.my-cluster.endpoint
}
