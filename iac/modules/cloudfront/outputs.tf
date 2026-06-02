output "distribution_id" {
  description = "CloudFront distribution ID — needed for cache invalidations in CI/CD"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_domain_name" {
  description = "CloudFront-assigned domain name (e.g. d1234abcd.cloudfront.net)"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}

output "logs_bucket_name" {
  description = "Name of the S3 bucket storing CloudFront access logs"
  value       = aws_s3_bucket.logs.id
}
