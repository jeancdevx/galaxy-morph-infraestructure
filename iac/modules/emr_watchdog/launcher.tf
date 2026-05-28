locals {
  emr_watchdog_zip = "${path.module}/../../../services/lambdas/emr_watchdog/dist/function.zip"

  common_env = {
    EMR_APPLICATION_ID       = var.emr_application_id
    EMR_EXECUTION_ROLE_ARN   = var.emr_execution_role_arn
    CHECKPOINTS_BUCKET       = var.checkpoints_bucket_name
    ARTIFACT_S3_PREFIX       = var.artifact_s3_prefix
    MSK_BOOTSTRAP_SERVERS    = var.msk_bootstrap_servers
    SAGEMAKER_ENDPOINT_NAME  = var.sagemaker_endpoint_name
    IMAGES_BUCKET            = var.images_bucket_name
    INFERENCE_MODE           = var.inference_mode
    KAFKA_INGESTION_TOPIC    = var.kafka_ingestion_topic
    KAFKA_RESULTS_TOPIC      = var.kafka_results_topic
    KAFKA_GROUP_ID           = var.kafka_group_id
    TRIGGER_INTERVAL_SECONDS = tostring(var.trigger_interval_seconds)
    INFERENCE_RETRIES        = tostring(var.inference_retries)
    SSM_JOB_RUN_ID_PARAMETER = aws_ssm_parameter.emr_job_run_id.name
    NAME_PREFIX              = var.name_prefix
  }
}

resource "aws_lambda_function" "emr_job_launcher" {
  #checkov:skip=CKV_AWS_116:Invoked by EventBridge (async); DLQ optional for dev
  #checkov:skip=CKV_AWS_173:Environment variables are AWS resource IDs and Spark config, not secrets
  function_name = "${var.name_prefix}-emr-job-launcher"
  role          = var.execution_role_arn
  runtime       = "nodejs22.x"
  handler       = "launcher.handler"
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

  depends_on = [aws_cloudwatch_log_group.emr_job_launcher]
}

resource "aws_cloudwatch_event_rule" "sagemaker_endpoint_in_service" {
  name        = "${var.name_prefix}-sagemaker-endpoint-in-service"
  description = "Triggers EMR job launcher when SageMaker endpoint reaches IN_SERVICE"

  event_pattern = jsonencode({
    source        = ["aws.sagemaker"]
    "detail-type" = ["SageMaker Endpoint State Change"]
    detail = {
      EndpointName   = [var.sagemaker_endpoint_name]
      EndpointStatus = ["IN_SERVICE"]
    }
  })
}

resource "aws_cloudwatch_event_target" "launch_emr_job" {
  rule = aws_cloudwatch_event_rule.sagemaker_endpoint_in_service.name
  arn  = aws_lambda_function.emr_job_launcher.arn
}

resource "aws_lambda_permission" "eventbridge_launcher" {
  #checkov:skip=CKV_AWS_364:source_arn is scoped to the specific EventBridge rule ARN
  statement_id  = "AllowEventBridgeLaunchEMR"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.emr_job_launcher.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.sagemaker_endpoint_in_service.arn
}
