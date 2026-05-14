locals {
  cloudwatch_log_group_name = "/aws/emr-serverless/${var.name_prefix}-streaming"
  s3_log_uri                = "s3://${var.log_bucket_name}/${var.log_prefix}/"
}

resource "aws_cloudwatch_log_group" "emr_serverless" {
  name              = local.cloudwatch_log_group_name
  retention_in_days = var.log_retention_days
}
