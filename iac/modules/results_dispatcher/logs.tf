resource "aws_cloudwatch_log_group" "results_dispatcher" {
  #checkov:skip=CKV_AWS_158:KMS encryption for CW logs not required in dev
  name              = "/aws/lambda/${var.name_prefix}-results-dispatcher"
  retention_in_days = var.log_retention_days
}
