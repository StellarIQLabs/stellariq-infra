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

# --- Networking ---

output "vpc_id" {
  description = "VPC identifier."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (web / load balancers)."
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (app workloads)."
  value       = module.networking.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Isolated database subnet IDs."
  value       = module.networking.database_subnet_ids
}

output "app_security_group_id" {
  description = "SG attached to application workloads."
  value       = module.networking.app_security_group_id
}

output "database_security_group_id" {
  description = "SG attached to RDS (accepts traffic from app SG only)."
  value       = module.networking.database_security_group_id
}

output "redis_security_group_id" {
  description = "SG attached to ElastiCache (accepts traffic from app SG only)."
  value       = module.networking.redis_security_group_id
}

# --- PostgreSQL ---

output "postgres_endpoint" {
  description = "RDS instance endpoint (host:port)."
  value       = module.postgres.endpoint
}

output "postgres_proxy_endpoint" {
  description = "RDS Proxy endpoint — use this in app DATABASE_URL for connection pooling."
  value       = module.postgres.proxy_endpoint
}

output "postgres_secret_arn" {
  description = "Secrets Manager ARN containing DB credentials."
  value       = module.postgres.secret_arn
}

output "postgres_database_name" {
  description = "PostgreSQL database name."
  value       = module.postgres.database_name
}

# --- Redis ---

output "redis_primary_endpoint" {
  description = "ElastiCache primary endpoint."
  value       = module.redis.primary_endpoint
}

output "redis_reader_endpoint" {
  description = "ElastiCache reader endpoint."
  value       = module.redis.reader_endpoint
}

output "redis_secret_arn" {
  description = "Secrets Manager ARN containing Redis URL."
  value       = module.redis.secret_arn
}

# --- Queues ---

output "queue_urls" {
  description = "SQS queue URLs (ingestion-jobs, analytics-pipelines, price-updates)."
  value       = module.queues.queue_urls
}

output "queue_arns" {
  description = "SQS queue ARNs."
  value       = module.queues.queue_arns
}

# --- Secrets ---

output "api_secret_arn" {
  description = "Secrets Manager ARN for API keys / JWT signing key."
  value       = module.secrets.api_secret_arn
}

output "app_config_secret_arn" {
  description = "Secrets Manager ARN for app configuration."
  value       = module.secrets.app_config_secret_arn
}

output "rotation_role_arn" {
  description = "IAM role ARN for secret rotation Lambda."
  value       = module.secrets.rotation_role_arn
}

output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator IRSA (replace ACCOUNT_ID/OIDC_PROVIDER placeholders)."
  value       = module.secrets.external_secrets_role_arn
}

# --- Registry ---

output "ecr_repository_urls" {
  description = "ECR repository URLs per service."
  value       = module.registry.repository_urls
}

output "wasm_artifact_bucket" {
  description = "S3 bucket for compiled Soroban contract WASM artifacts."
  value       = module.registry.wasm_bucket
}

# --- Backups ---

output "backup_vault_arn" {
  description = "AWS Backup vault ARN."
  value       = module.backups.vault_arn
}

output "backup_plan_id" {
  description = "AWS Backup plan ID."
  value       = module.backups.plan_id
}

# --- Cluster (conditional: not created for dev) ---

output "cluster_endpoint" {
  description = "EKS API server endpoint (null when environment=dev)."
  value       = try(module.cluster[0].cluster_endpoint, null)
}

output "cluster_ca_data" {
  description = "EKS cluster CA certificate (base64, null when environment=dev)."
  value       = try(module.cluster[0].cluster_ca_data, null)
}

output "cluster_node_role_arn" {
  description = "IAM role ARN for EKS managed node group (null when environment=dev)."
  value       = try(module.cluster[0].node_role_arn, null)
}
