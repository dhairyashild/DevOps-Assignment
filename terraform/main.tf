module "vpc" {
  source = "./modules/vpc"
  
  vpc_name      = "devops-assignment-vpc"
  vpc_cidr      = "10.0.0.0/16"
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  azs           = ["ap-south-1a", "ap-south-1b"]
}

resource "aws_ecs_cluster" "foo" {
  name = "white-hart"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Backend Task - YOUR ECR IMAGE
resource "aws_ecs_task_definition" "backend" {
  family                   = "devops-backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  
  container_definitions = jsonencode([{
    name      = "backend"
    image     = "570043747352.dkr.ecr.ap-south-1.amazonaws.com/devops-backend:latest"
    essential = true
    cpu       = 512
    memory    = 1024
    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/devops-backend"
        "awslogs-region"        = "ap-south-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# Frontend Task - YOUR ECR IMAGE
resource "aws_ecs_task_definition" "frontend" {
  family                   = "devops-frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  
  container_definitions = jsonencode([{
    name      = "frontend"
    image     = "570043747352.dkr.ecr.ap-south-1.amazonaws.com/devops-frontend:latest"
    essential = true
    cpu       = 512
    memory    = 1024
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]
    environment = [{
      name  = "NEXT_PUBLIC_API_URL"
      value = "http://localhost:8000"
    }]
  }])
}
