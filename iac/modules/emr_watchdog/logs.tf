resource "aws_cloudwatch_log_group" "emr_job_launcher" {
  #checkov:skip=CKV_AWS_158:KMS encryption for CW logs not required in this environment
  name              = "/aws/lambda/${var.name_prefix}-emr-job-launcher"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "emr_job_watchdog" {
  #checkov:skip=CKV_AWS_158:KMS encryption for CW logs not required in this environment
  name              = "/aws/lambda/${var.name_prefix}-emr-job-watchdog"
  retention_in_days = var.log_retention_days
}
