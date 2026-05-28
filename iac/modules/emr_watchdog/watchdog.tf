resource "aws_lambda_function" "emr_job_watchdog" {
  #checkov:skip=CKV_AWS_116:Invoked by EventBridge (async); DLQ optional for dev
  #checkov:skip=CKV_AWS_173:Environment variables are AWS resource IDs and Spark config, not secrets
  function_name = "${var.name_prefix}-emr-job-watchdog"
  role          = var.execution_role_arn
  runtime       = "nodejs22.x"
  handler       = "watchdog.handler"
  timeout       = 60
  memory_size   = 128

  filename         = local.emr_watchdog_zip
  source_code_hash = try(filebase64sha256(local.emr_watchdog_zip), null)

  environment {
    variables = local.common_env
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [aws_cloudwatch_log_group.emr_job_watchdog]
}

resource "aws_cloudwatch_event_rule" "emr_job_failed" {
  name        = "${var.name_prefix}-emr-job-failed"
  description = "Triggers EMR job watchdog when a streaming job reaches FAILED or CANCELLED"

  event_pattern = jsonencode({
    source        = ["aws.emr-serverless"]
    "detail-type" = ["EMR Serverless Job Run State Change"]
    detail = {
      applicationId = [var.emr_application_id]
      state         = ["FAILED", "CANCELLED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "restart_emr_job" {
  rule = aws_cloudwatch_event_rule.emr_job_failed.name
  arn  = aws_lambda_function.emr_job_watchdog.arn
}

resource "aws_lambda_permission" "eventbridge_watchdog" {
  #checkov:skip=CKV_AWS_364:source_arn is scoped to the specific EventBridge rule ARN
  statement_id  = "AllowEventBridgeRestartEMR"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.emr_job_watchdog.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.emr_job_failed.arn
}
