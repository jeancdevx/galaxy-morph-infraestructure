output "images_bucket_name" {
  description = "Name of the images S3 bucket"
  value       = aws_s3_bucket.this["images"].id
}

output "images_bucket_arn" {
  description = "ARN of the images S3 bucket"
  value       = aws_s3_bucket.this["images"].arn
}

output "checkpoints_bucket_name" {
  description = "Name of the checkpoints S3 bucket"
  value       = aws_s3_bucket.this["checkpoints"].id
}

output "checkpoints_bucket_arn" {
  description = "ARN of the checkpoints S3 bucket"
  value       = aws_s3_bucket.this["checkpoints"].arn
}

output "models_bucket_name" {
  description = "Name of the models S3 bucket"
  value       = aws_s3_bucket.this["models"].id
}

output "models_bucket_arn" {
  description = "ARN of the models S3 bucket"
  value       = aws_s3_bucket.this["models"].arn
}
