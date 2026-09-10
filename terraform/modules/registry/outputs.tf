output "repository_urls" {
  value = { for k, r in aws_ecr_repository.services : k => r.repository_url }
}

output "wasm_bucket" {
  value = aws_s3_bucket.wasm.bucket
}
