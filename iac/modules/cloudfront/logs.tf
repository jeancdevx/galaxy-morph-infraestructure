resource "aws_s3_bucket" "logs" {
  #checkov:skip=CKV_AWS_19:Server-side encryption optional for access logs in dev
  #checkov:skip=CKV_AWS_144:Cross-region replication not required for logs
  #checkov:skip=CKV2_AWS_6:Public access controlled by aws_s3_bucket_public_access_block
  bucket = "${var.name_prefix}-cloudfront-logs"

  tags = {
    Name = "${var.name_prefix}-cloudfront-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront log delivery requires BucketOwnerPreferred + log-delivery-write ACL
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]

  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.log_retention_days
    }
  }
}
