resource "aws_s3_bucket" "terraform_state" {
  #checkov:skip=CKV_AWS_20:Public access controlled by aws_s3_bucket_public_access_block
  #checkov:skip=CKV_AWS_57:Public access controlled by aws_s3_bucket_public_access_block
  #checkov:skip=CKV2_AWS_6:Public access controlled by aws_s3_bucket_public_access_block
  #checkov:skip=CKV_AWS_19:Encryption configured via aws_s3_bucket_server_side_encryption_configuration; CMK optional in dev
  #checkov:skip=CKV2_AWS_61:Lifecycle configured via separate aws_s3_bucket_lifecycle_configuration resource
  bucket = local.state_bucket_name
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
