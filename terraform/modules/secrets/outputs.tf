output "api_secret_arn" {
  value = aws_secretsmanager_secret.api.arn
}

output "app_config_secret_arn" {
  value = aws_secretsmanager_secret.app_config.arn
}

output "rotation_role_arn" {
  value = aws_iam_role.rotation.arn
}

output "external_secrets_role_arn" {
  value = aws_iam_role.external_secrets.arn
}
