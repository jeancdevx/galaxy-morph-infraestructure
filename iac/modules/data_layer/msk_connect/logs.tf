resource "aws_cloudwatch_log_group" "connector" {
  count = var.enable_connector ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.cloudwatch_log_retention_days
}
