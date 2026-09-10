output "endpoint" {
  value = aws_db_instance.main.endpoint
}

output "proxy_endpoint" {
  description = "Use this in app DATABASE_URL for pooling."
  value       = aws_db_proxy.main.endpoint
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "database_name" {
  value = var.database_name
}
