output "environment" {
  description = "Active environment."
  value       = var.environment
}

output "aws_region" {
  description = "Active AWS region."
  value       = var.aws_region
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = local.cluster_name
}
