resource "aws_cloudwatch_log_group" "waf" {
  #checkov:skip=CKV_AWS_158:KMS encryption for CW logs not required in this environment
  # WAF log group name must start with "aws-waf-logs-" (AWS requirement)
  name              = "aws-waf-logs-${var.name_prefix}-${lower(var.scope)}"
  retention_in_days = var.log_retention_days
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  resource_arn            = aws_wafv2_web_acl.this.arn
}
