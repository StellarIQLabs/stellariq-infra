locals {
  images = ["web", "api", "indexer", "price-engine", "analytics-engine", "routing-engine", "simulator"]
}

resource "aws_ecr_repository" "services" {
  for_each             = toset(local.images)
  name                 = "${var.name_prefix}/${each.key}"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  image_scanning_configuration { scan_on_push = true }

  encryption_configuration { encryption_type = "AES256" }
  tags = { Name = "${var.name_prefix}-${each.key}" }
}

resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = toset(local.images)
  repository = aws_ecr_repository.services[each.key].name
  policy = jsonencode({
    rules = [
      { rulePriority = 1, description = "Keep last 30 tagged",
        selection = { tagStatus = "tagged", tagPrefixList = ["v", "sha-"], countType = "imageCountMoreThan", countNumber = 30 },
        action = { type = "expire" } },
      { rulePriority = 2, description = "Expire untagged after 7d",
        selection = { tagStatus = "untagged", countType = "sinceImagePushed", countUnit = "days", countNumber = 7 },
        action = { type = "expire" } },
    ]
  })
}

# WASM artifact bucket for compiled Soroban contracts
resource "aws_s3_bucket" "wasm" {
  bucket = "${var.name_prefix}-contract-artifacts"
  tags   = { Name = "${var.name_prefix}-contract-artifacts" }
}

resource "aws_s3_bucket_versioning" "wasm" {
  bucket = aws_s3_bucket.wasm.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "wasm" {
  bucket = aws_s3_bucket.wasm.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}

resource "aws_s3_bucket_public_access_block" "wasm" {
  bucket                  = aws_s3_bucket.wasm.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
