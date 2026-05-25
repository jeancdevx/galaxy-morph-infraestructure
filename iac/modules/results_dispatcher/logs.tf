resource "aws_cloudwatch_log_group" "results_dispatcher" {
  name              = "/aws/lambda/${var.name_prefix}-results-dispatcher"
  retention_in_days = var.log_retention_days
}
