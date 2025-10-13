# DevOps Assignment - Deployment Guide

## Overview
This guide walks through deploying the FastAPI + Next.js application on AWS using Terraform and GitHub Actions.

## Architecture
- **Frontend**: Next.js on ECS Fargate (Port 3000)
- **Backend**: FastAPI on ECS Fargate (Port 8000)
- **Load Balancer**: Application Load Balancer
- **Infrastructure**: Terraform-managed AWS resources
- **CI/CD**: GitHub Actions

## Prerequisites

### 1. AWS Account Setup
- AWS CLI configured with credentials
- IAM user with appropriate permissions (ECR, ECS, VPC, CloudWatch, S3)

### 2. Local Development Tools
- Docker & Docker Compose
- Git
- Node.js 18+
- Python 3.9+

## Deployment Steps

### Step 1: Clone and Setup
```bash
git clone https://github.com/dhairyashild/DevOps-Assignment.git
cd DevOps-Assignment
```

### Step 2: Test Locally
```bash
# Using Docker Compose
docker-compose up -d

# Access applications:
# Frontend: http://localhost:3000
# Backend: http://localhost:8000
# Backend Docs: http://localhost:8000/docs
```

### Step 3: Infrastructure Deployment

#### 3.1 Create S3 Bucket for Terraform State
```bash
aws s3 mb s3://devops-assignment-tfstate --region us-east-1
```

#### 3.2 Deploy Infrastructure
```bash
cd infrastructure

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="alert_email=your-email@example.com"

# Apply infrastructure
terraform apply -var="alert_email=your-email@example.com"
```

#### 3.3 Note Outputs
After deployment, note these outputs:
- ECR repository URLs
- ALB DNS name
- CloudWatch dashboard URL

### Step 4: Configure GitHub Secrets

In your GitHub repository, add these secrets:
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_REGION`: us-east-1

### Step 5: CI/CD Pipeline

#### 5.1 Merge to Develop Branch
- Push to `develop` branch triggers CI pipeline
- Tests run automatically
- Docker images built and pushed to ECR

#### 5.2 Merge to Main Branch
- Push to `main` branch triggers CD pipeline
- New Docker images deployed to ECS
- Zero-downtime deployment

## Monitoring & Alerts

### CloudWatch Dashboard
- Access via AWS Console or Terraform output
- Monitor: CPU, memory, request counts, error rates

### Alerts Configured
- CPU > 70% for 5 minutes
- Memory > 80% for 5 minutes
- 5xx errors > 10 in 5 minutes

### Access Applications
- Frontend: http://ALB-DNS-NAME (from Terraform output)
- Backend API: http://ALB-DNS-NAME/api
- Backend Docs: http://ALB-DNS-NAME/api/docs

## Cleanup
To destroy all resources:
```bash
cd infrastructure
terraform destroy -var="alert_email=your-email@example.com"
```
