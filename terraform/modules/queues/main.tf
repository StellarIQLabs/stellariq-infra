# Ingestion + analytics queues with DLQs and FIFO where ordering matters.

locals {
  queues = {
    ingestion-jobs      = { fifo = false, visibility_timeout = 300 }
    ingestion-jobs-dlq  = { fifo = false, visibility_timeout = 300 }
    analytics-pipelines = { fifo = false, visibility_timeout = 600 }
    price-updates       = { fifo = true, visibility_timeout = 60 }
  }
}

resource "aws_sqs_queue" "dlq" {
  for_each = { for k, v in local.queues : k => v if strcontains(k, "dlq") }

  name                      = "${var.name_prefix}-${each.key}"
  message_retention_seconds = 1209600 # 14 days
  sqs_managed_sse_enabled   = true
  tags                      = { Name = "${var.name_prefix}-${each.key}" }
}

resource "aws_sqs_queue" "main" {
  for_each = { for k, v in local.queues : k => v if !strcontains(k, "dlq") }

  name                        = "${var.name_prefix}-${each.key}${each.value.fifo ? ".fifo" : ""}"
  fifo_queue                  = each.value.fifo
  content_based_deduplication = each.value.fifo
  visibility_timeout_seconds  = each.value.visibility_timeout
  message_retention_seconds   = 604800 # 7 days
  sqs_managed_sse_enabled     = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq["${split(".", each.key)[0]}-dlq"].arn
    maxReceiveCount     = 5
  })

  tags = { Name = "${var.name_prefix}-${each.key}" }
}
