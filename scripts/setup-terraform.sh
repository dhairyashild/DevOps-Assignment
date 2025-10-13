#!/bin/bash

echo "Setting up Terraform for DevOps Assignment..."

cat << EOL
Manual steps required:

1. Create S3 bucket for Terraform state:
   aws s3 mb s3://devops-assignment-tfstate --region us-east-1

2. Update backend configuration in infrastructure/main.tf with your bucket name

3. Initialize Terraform:
   cd infrastructure
   terraform init

4. Plan and apply:
   terraform plan -var="alert_email=your-email@example.com"
   terraform apply -var="alert_email=your-email@example.com"

EOL
