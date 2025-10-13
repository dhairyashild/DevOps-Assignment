# Quick Start Guide

## 5-Minute Setup

### 1. Prerequisites Check
```bash
docker --version
terraform --version
aws --version
git --version
```

### 2. Clone & Setup
```bash
git clone https://github.com/dhairyashild/DevOps-Assignment.git
cd DevOps-Assignment
```

### 3. Local Test
```bash
docker-compose up -d
# Visit http://localhost:3000
```

### 4. AWS Setup
```bash
aws configure
aws s3 mb s3://devops-assignment-tfstate --region us-east-1
```

### 5. Deploy Infrastructure
```bash
cd infrastructure
terraform init
terraform apply -var="alert_email=your-email@example.com"
```

### 6. Configure GitHub
- Add AWS credentials as secrets
- Merge feature branch to develop

### 7. Access Your Application
- Use ALB DNS name from Terraform outputs
- Monitor via CloudWatch dashboard

## What You Get

✅ **Infrastructure**: VPC, ECS, ALB, ECR
✅ **CI/CD**: Automated testing and deployment
✅ **Monitoring**: CloudWatch dashboard and alerts
✅ **Security**: IAM roles, security groups
✅ **High Availability**: Multi-AZ deployment
