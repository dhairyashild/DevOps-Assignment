terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # This will be filled in after creating the S3 bucket
    bucket = "devops-assignment-tfstate"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
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

# ECS Cluster and Services module
module "ecs" {
  source = "./modules/ecs"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.network.vpc_id
  public_subnets        = module.network.public_subnets
  private_subnets       = module.network.private_subnets
  alb_security_group_id = module.security.alb_security_group_id
  ecs_security_group_id = module.security.ecs_security_group_id

  backend_ecr_repository = aws_ecr_repository.backend.repository_url
  frontend_ecr_repository = aws_ecr_repository.frontend.repository_url

  backend_image_tag  = var.backend_image_tag
  frontend_image_tag = var.frontend_image_tag
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-backend"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}-frontend"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Monitoring module
module "monitoring" {
  source = "./modules/monitoring"

  project_name         = var.project_name
  environment          = var.environment
  aws_region           = var.aws_region
  ecs_cluster_name     = module.ecs.ecs_cluster_name
  backend_service_name = "${var.project_name}-backend-service"
  frontend_service_name = "${var.project_name}-frontend-service"
  alert_email          = var.alert_email
}

# Add ALB reference for monitoring module
resource "aws_lb" "main" {
  # This is a reference to the ALB created in the ECS module
  # The actual ALB is defined in the ECS module
}

# Monitoring module
module "monitoring" {
  source = "./modules/monitoring"

  project_name         = var.project_name
  environment          = var.environment
  aws_region           = var.aws_region
  ecs_cluster_name     = module.ecs.ecs_cluster_name
  backend_service_name = "${var.project_name}-backend-service"
  frontend_service_name = "${var.project_name}-frontend-service"
  alb_arn_suffix       = split("/", module.ecs.alb_dns_name)[1] # Extract ALB name from DNS
  alert_email          = var.alert_email
}
