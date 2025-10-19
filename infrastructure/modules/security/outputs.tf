output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "eks_security_group_id" {
  description = "EKS security group ID"
  value       = aws_security_group.eks.id
}
