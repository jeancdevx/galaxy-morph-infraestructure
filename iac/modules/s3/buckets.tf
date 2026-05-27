locals {
  buckets = {
    images      = var.images_bucket_name
    checkpoints = var.checkpoints_bucket_name
    models      = var.models_bucket_name
  }
}

resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_20:Public access controlled by aws_s3_bucket_public_access_block
  #checkov:skip=CKV_AWS_57:Public access controlled by aws_s3_bucket_public_access_block
  #checkov:skip=CKV2_AWS_6:Public access controlled by aws_s3_bucket_public_access_block
  #checkov:skip=CKV_AWS_19:Encryption configured via aws_s3_bucket_server_side_encryption_configuration; CMK optional in dev
  for_each = local.buckets

  bucket = each.value

  tags = {
    Name = each.value
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = local.buckets

  bucket = aws_s3_bucket.this[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = local.buckets

  bucket = aws_s3_bucket.this[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = local.buckets

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
