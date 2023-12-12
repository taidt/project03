terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
  required_version = ">= 0.12"
}

provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.response_body)}/32"
  azs                       = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_cidr                  = "10.0.0.0/16"
}

resource "aws_ecr_repository" "project03" {
  name = var.prj03_ecr_name
}


resource "aws_vpc" "project03" {
  cidr_block = local.vpc_cidr
  tags = tomap({
    "Name"                                                = "prj03_terraform-eks-vpc",
    "kubernetes.io/cluster/${var.prj03_eks_cluster_name}" = "shared",
  })
}

resource "aws_subnet" "project03" {
  count = 2

  availability_zone       = local.azs[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.project03.id

  tags = tomap({
    "Name"                                                = "terraform-eks-subnet",
    "kubernetes.io/cluster/${var.prj03_eks_cluster_name}" = "shared",
  })
}

resource "aws_internet_gateway" "project03" {
  vpc_id = aws_vpc.project03.id

  tags = {
    Name = "terraform-eks-igw"
  }
}

resource "aws_route_table" "project03" {
  vpc_id = aws_vpc.project03.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project03.id
  }
}

resource "aws_route_table_association" "project03" {
  count = 2

  subnet_id      = aws_subnet.project03[count.index].id
  route_table_id = aws_route_table.project03.id
}

resource "aws_ecr_repository_policy" "project03" {
  repository = aws_ecr_repository.project03.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPushPull"
        Effect = "Allow"
        Principal = {
          AWS = aws_codebuild_project.project03.service_role
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "eks_cluster_role" {
  name = var.prj03_eks_cluster_role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceControllerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_security_group" "eks_cluster_security_group" {
  name        = var.prj03_eks_cluster_security_group
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.project03.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.workstation-external-cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-eks"
  }
}

resource "aws_eks_cluster" "project03" {
  name     = var.prj03_eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  vpc_config {
    subnet_ids         = aws_subnet.project03[*].id
    security_group_ids = [aws_security_group.eks_cluster_security_group.id]
  }
}

resource "aws_iam_role" "eks_worker_node_role" {
  name = var.prj03_eks_worker_node_role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_worker_node_role.name
}


resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_worker_node_role.name
}


resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_worker_node_role.name
}


resource "aws_eks_node_group" "project03" {
  cluster_name    = aws_eks_cluster.project03.name
  node_group_name = var.prj03_eks_worker_node_name
  node_role_arn   = aws_iam_role.eks_worker_node_role.arn
  subnet_ids      = aws_subnet.project03[*].id

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_worker_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_worker_node_AmazonEC2ContainerRegistryReadOnly,
  ]
}


resource "aws_security_group" "eks_worker_node_security_group" {
  name        = var.prj03_eks_worker_node_security_group
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.project03.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-worker-node-security-group"
  }
}


resource "aws_security_group_rule" "node-ingress-self" {
  description              = "Allow node to communicate with each other"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_worker_node_security_group.id
  source_security_group_id = aws_security_group.eks_worker_node_security_group.id
}

resource "aws_security_group_rule" "node-ingress-cluster-https" {
  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster API server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_node_security_group.id
  source_security_group_id = aws_security_group.eks_cluster_security_group.id
}

resource "aws_security_group_rule" "node-ingress-cluster-others" {
  description              = "Allow pods to communicate with the cluster API Server"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker_node_security_group.id
  source_security_group_id = aws_security_group.eks_cluster_security_group.id
}

resource "aws_security_group_rule" "cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_security_group.id
  source_security_group_id = aws_security_group.eks_worker_node_security_group.id
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "example" {
  name               = var.prj03_codebuild-ecr-role
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "example" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:*",
      "cloudtrail:LookupEvents"
    ]
    resources = ["*"]
  }


  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "replication.ecr.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy" "example" {
  role   = aws_iam_role.example.name
  policy = data.aws_iam_policy_document.example.json
}

resource "aws_codebuild_source_credential" "example" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.prj03_github_access_token
}

resource "aws_codebuild_project" "project03" {
  name          = var.prj03_ecr_name
  description   = "CodeBuild project for the ECR repository"
  build_timeout = "5"
  service_role  = aws_iam_role.example.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "us-east-1"
    }

    environment_variable {
      name  = "AWS_ECR_REPOSITORY"
      value = aws_ecr_repository.project03.name
    }

    environment_variable {
      name  = "AWS_ECR_REPOSITORY_URL"
      value = aws_ecr_repository.project03.repository_url
    }
  }

  source {
    type            = "GITHUB"
    location        = var.prj03_git_repo_url
    git_clone_depth = 1
    buildspec       = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "log-group"
      stream_name = "log-stream"
    }
  }

  tags = {
    Name = "terraform-ecr-demo"
  }
}

resource "aws_codebuild_webhook" "project03" {
  project_name = aws_codebuild_project.project03.name
}