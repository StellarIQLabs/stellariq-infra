# Secrets foundation: app-level secrets + rotation-ready config. Nothing secret is committed.
resource "aws_secretsmanager_secret" "api" {
  name                    = "${var.name_prefix}/api"
  description             = "StellarIQ API keys, JWT signing key, Soroban RPC keys"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret" "app_config" {
  name                    = "${var.name_prefix}/app-config"
  description             = "Non-sensitive app config mirrored for ExternalSecrets"
  recovery_window_in_days = 7
}

# Rotation Lambda placeholder role (rotation function deployed via scripts/rotate-secrets)
resource "aws_iam_role" "rotation" {
  name = "${var.name_prefix}-secrets-rotation"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

# IRSA role for External Secrets Operator to read the above secrets
resource "aws_iam_role" "external_secrets" {
  name = "${var.name_prefix}-external-secrets"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = { Federated = "arn:aws:iam::ACCOUNT_ID:oidc-provider/OIDC_PROVIDER" }
      Condition = { StringEquals = { "sub" = "system:serviceaccount:external-secrets:external-secrets" } }
    }]
  })
}

resource "aws_iam_role_policy" "external_secrets" {
  name = "${var.name_prefix}-external-secrets-read"
  role = aws_iam_role.external_secrets.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = [aws_secretsmanager_secret.api.arn, aws_secretsmanager_secret.app_config.arn]
    }]
  })
}
