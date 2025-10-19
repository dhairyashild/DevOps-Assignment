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

  project_name     = var.project_name
  environment      = var.environment
  private_subnets  = module.network.private_subnets
  cluster_version  = var.cluster_version
}

# Kubernetes manifests
resource "kubectl_manifest" "backend_deployment" {
  yaml_body = templatefile("${path.module}/modules/eks/k8s/backend/deployment.yaml", {
    BACKEND_IMAGE = "${aws_ecr_repository.backend.repository_url}:latest"
  })
  depends_on = [module.eks]
}

resource "kubectl_manifest" "backend_service" {
  yaml_body = file("${path.module}/modules/eks/k8s/backend/service.yaml")
  depends_on = [module.eks]
}

resource "kubectl_manifest" "frontend_deployment" {
  yaml_body = templatefile("${path.module}/modules/eks/k8s/frontend/deployment.yaml", {
    FRONTEND_IMAGE = "${aws_ecr_repository.frontend.repository_url}:latest"
  })
  depends_on = [module.eks]
}

resource "kubectl_manifest" "frontend_service" {
  yaml_body = file("${path.module}/modules/eks/k8s/frontend/service.yaml")
  depends_on = [module.eks]
}

resource "kubectl_manifest" "ingress" {
  yaml_body = file("${path.module}/modules/eks/k8s/ingress/ingress.yaml")
  depends_on = [module.eks]
}

# CloudWatch Log Groups (keep for EKS)
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
