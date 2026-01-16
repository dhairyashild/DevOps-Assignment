output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.foo.name
}

output "backend_task_arn" {
  description = "Backend task ARN"
  value       = aws_ecs_task_definition.backend.arn
}

output "frontend_task_arn" {
  description = "Frontend task ARN"
  value       = aws_ecs_task_definition.frontend.arn
}
