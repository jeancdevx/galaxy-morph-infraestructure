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

  lambda_log_arns = [
    "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${var.name_prefix}-*",
    "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${var.name_prefix}-*:*",
  ]

  # EMR Serverless uses a single fixed log group /aws/emr-serverless (not
  # per-deployment). Log streams are differentiated by application/job IDs.
  emr_log_arns = [
    "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/emr-serverless",
    "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/emr-serverless:*",
  ]

  sagemaker_log_arns = [
    "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/sagemaker/Endpoints/${var.name_prefix}-*",
    "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/sagemaker/Endpoints/${var.name_prefix}-*:*",
  ]

  msk_connect_log_arns = [
    "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/kafkaconnect/connectors/${var.name_prefix}-*",
    "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/kafkaconnect/connectors/${var.name_prefix}-*:*",
  ]
}
