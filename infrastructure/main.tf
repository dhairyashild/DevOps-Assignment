terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }

  backend "s3" {
    bucket = "devops-assignment-tfstate"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.main.token
  load_config_file       = false
}

data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name
}

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Network module
module "network" {
  source = "./modules/network"

  project_name     = var.project_name
  environment      = var.environment
  vpc_cidr         = var.vpc_cidr
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  availability_zones = var.availability_zones
}

# Security module
module "security" {
  source = "./modules/security"

  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.network.vpc_id
  private_subnets = module.network.private_subnets
}

# ECR Repositories
resource "aws_ecr_repository" "backend" {
  name = "${var.project_name}-backend"
  
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecr_repository" "frontend" {
  name = "${var.project_name}-frontend"
  
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# EKS module
module "eks" {
  source = "./modules/eks"

  project_name          = var.project_name
  environment           = var.environment
  private_subnets       = module.network.private_subnets
  cluster_version       = var.cluster_version
  eks_security_group_id = module.security.eks_security_group_id
}

# ALB Controller IAM Policy
data "aws_iam_policy_document" "alb_controller" {
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeCoipPools",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTags"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "alb_controller" {
  name        = "${var.project_name}-alb-controller"
  description = "Policy for ALB Controller"
  policy      = data.aws_iam_policy_document.alb_controller.json
}

# ALB Controller IAM Role
resource "aws_iam_role" "alb_controller" {
  name = "${var.project_name}-alb-controller"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.eks.cluster_endpoint, "https://", "")}"
      }
      Condition = {
        StringEquals = {
          "${replace(module.eks.cluster_endpoint, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
    Version = "2012-10-17"
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  policy_arn = aws_iam_policy.alb_controller.arn
  role       = aws_iam_role.alb_controller.name
}

# Kubernetes manifests
resource "kubectl_manifest" "alb_controller" {
  yaml_body = templatefile("${path.module}/modules/eks/k8s/ingress/alb-controller.yaml", {
    CLUSTER_NAME = module.eks.cluster_name
  })
  depends_on = [module.eks]
}

resource "kubectl_manifest" "backend_deployment" {
  yaml_body = templatefile("${path.module}/modules/eks/k8s/backend/deployment.yaml", {
    BACKEND_IMAGE = "${aws_ecr_repository.backend.repository_url}:latest"
  })
  depends_on = [module.eks, kubectl_manifest.alb_controller]
}

resource "kubectl_manifest" "backend_service" {
  yaml_body = file("${path.module}/modules/eks/k8s/backend/service.yaml")
  depends_on = [module.eks]
}

resource "kubectl_manifest" "frontend_deployment" {
  yaml_body = templatefile("${path.module}/modules/eks/k8s/frontend/deployment.yaml", {
    FRONTEND_IMAGE = "${aws_ecr_repository.frontend.repository_url}:latest"
  })
  depends_on = [module.eks, kubectl_manifest.alb_controller]
}

resource "kubectl_manifest" "frontend_service" {
  yaml_body = file("${path.module}/modules/eks/k8s/frontend/service.yaml")
  depends_on = [module.eks]
}

resource "kubectl_manifest" "ingress" {
  yaml_body = file("${path.module}/modules/eks/k8s/ingress/ingress.yaml")
  depends_on = [kubectl_manifest.alb_controller, kubectl_manifest.backend_service, kubectl_manifest.frontend_service]
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/eks/${var.project_name}-backend"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/eks/${var.project_name}-frontend"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Monitoring module
module "monitoring" {
  source = "./modules/monitoring"

  project_name     = var.project_name
  environment      = var.environment
  aws_region       = var.aws_region
  eks_cluster_name = module.eks.cluster_name
  alert_email      = var.alert_email
}
