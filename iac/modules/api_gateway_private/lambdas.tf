locals {
  upload_api_zip    = "${path.module}/../../../services/lambdas/upload_api/dist/function.zip"
  ingestion_api_zip = "${path.module}/../../../services/lambdas/ingestion_api/dist/function.zip"
}

resource "aws_cloudwatch_log_group" "upload_api" {
  #checkov:skip=CKV_AWS_158:KMS encryption for CW logs not required in dev
  name              = "/aws/lambda/${var.name_prefix}-upload-api"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "upload_api" {
  #checkov:skip=CKV_AWS_116:DLQ applies to async invocations only; upload_api is invoked synchronously by API Gateway
  #checkov:skip=CKV_AWS_173:Environment variables are resource IDs (IMAGES_BUCKET_NAME), not secrets
  function_name = "${var.name_prefix}-upload-api"
  role          = var.upload_api_role_arn
  runtime       = "nodejs22.x"
  handler       = "index.handler"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  filename         = local.upload_api_zip
  source_code_hash = try(filebase64sha256(local.upload_api_zip), null)

  environment {
    variables = {
      IMAGES_BUCKET_NAME      = var.images_bucket_name
      CORS_ALLOW_ORIGINS      = join(",", var.cors_allow_origins)
      POWERTOOLS_SERVICE_NAME = "upload-api"
      LOG_LEVEL               = "INFO"
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [aws_cloudwatch_log_group.upload_api]
}

resource "aws_lambda_permission" "upload_api" {
  #checkov:skip=CKV_AWS_364:source_arn is scoped to this API Gateway execution ARN
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.private.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "ingestion_api" {
  #checkov:skip=CKV_AWS_158:KMS encryption for CW logs not required in dev
  name              = "/aws/lambda/${var.name_prefix}-ingestion-api"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "ingestion_api" {
  #checkov:skip=CKV_AWS_116:DLQ applies to async invocations only; ingestion_api is invoked synchronously by API Gateway
  #checkov:skip=CKV_AWS_173:Environment variables are resource IDs (JOBS_TABLE_NAME, INGESTION_QUEUE_URL), not secrets
  function_name = "${var.name_prefix}-ingestion-api"
  role          = var.ingestion_api_role_arn
  runtime       = "nodejs22.x"
  handler       = "index.handler"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  filename         = local.ingestion_api_zip
  source_code_hash = try(filebase64sha256(local.ingestion_api_zip), null)

  environment {
    variables = {
      JOBS_TABLE_NAME         = var.jobs_table_name
      INGESTION_QUEUE_URL     = var.ingestion_queue_url
      CORS_ALLOW_ORIGINS      = join(",", var.cors_allow_origins)
      POWERTOOLS_SERVICE_NAME = "ingestion-api"
      LOG_LEVEL               = "INFO"
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [aws_cloudwatch_log_group.ingestion_api]
}

resource "aws_lambda_permission" "ingestion_api" {
  #checkov:skip=CKV_AWS_364:source_arn is scoped to this API Gateway execution ARN
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.private.execution_arn}/*/*"
}
