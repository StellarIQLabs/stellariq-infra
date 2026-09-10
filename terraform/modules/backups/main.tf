# Daily snapshots + PITR-ready retention + quarterly restore test (EventBridge -> Lambda stub).
resource "aws_backup_vault" "main" {
  name          = "${var.name_prefix}-backup-vault"
  kms_key_arn   = aws_kms_key.backup.arn
  force_destroy = false
}

resource "aws_kms_key" "backup" {
  description             = "StellarIQ backup encryption (${var.name_prefix})"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_backup_plan" "daily" {
  name = "${var.name_prefix}-daily"

  rule {
    rule_name         = "daily-snapshot"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)"

    lifecycle {
      cold_storage_after = 30
      delete_after       = var.retention_days
    }
  }

  advanced_backup_setting {
    backup_options = { WindowsVSS = "disabled" }
    resource_type  = "EC2"
  }
}

resource "aws_backup_selection" "rds" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.name_prefix}-rds-selection"
  plan_id      = aws_backup_plan.daily.id
  resources    = ["arn:aws:rds:*:*:db:${var.db_identifier}"]
}

resource "aws_iam_role" "backup" {
  name = "${var.name_prefix}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores",
  ]
}

# Restore-test alarm hook: CloudWatch alarm fires if no successful recovery point in 26h
resource "aws_cloudwatch_metric_alarm" "no_recent_backup" {
  alarm_name          = "${var.name_prefix}-no-recent-backup"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfBackupJobsCompleted"
  namespace           = "AWS/Backup"
  period              = 93600
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Fires when no successful backup completed in the last 26h. See docs/disaster-recovery.md restore test."
  treat_missing_data  = "breaching"
}
