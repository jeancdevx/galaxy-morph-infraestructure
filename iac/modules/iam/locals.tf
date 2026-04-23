locals {
  jobs_table_arn = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.jobs_table_name}"

  images_bucket_arn      = "arn:aws:s3:::${var.images_bucket_name}"
  images_bucket_all_arn  = "arn:aws:s3:::${var.images_bucket_name}/*"
  models_bucket_arn      = "arn:aws:s3:::${var.models_bucket_name}"
  models_bucket_all_arn  = "arn:aws:s3:::${var.models_bucket_name}/*"
  checkpoints_bucket_arn = "arn:aws:s3:::${var.checkpoints_bucket_name}"
  checkpoints_all_arn    = "arn:aws:s3:::${var.checkpoints_bucket_name}/*"
  raw_bucket_arn         = "arn:aws:s3:::${var.raw_bucket_name}"
  raw_bucket_all_arn     = "arn:aws:s3:::${var.raw_bucket_name}/*"
}
