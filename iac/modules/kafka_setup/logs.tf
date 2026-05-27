resource "aws_cloudwatch_log_group" "kafka_setup" {
  #checkov:skip=CKV_AWS_158:KMS encryption for CW logs not required in this environment
  name              = "/aws/lambda/${var.name_prefix}-kafka-setup"
  retention_in_days = var.log_retention_days
}
