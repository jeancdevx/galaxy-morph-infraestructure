locals {
  auth_api_zip           = "${path.module}/../../../services/lambdas/auth_api/dist/function.zip"
  classification_api_zip = "${path.module}/../../../services/lambdas/classification_api/dist/function.zip"
}

resource "aws_cloudwatch_log_group" "auth_api" {
  #checkov:skip=CKV_AWS_158:KMS encryption for CW logs not required in dev
  name              = "/aws/lambda/${var.name_prefix}-auth-api"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "auth_api" {
  #checkov:skip=CKV_AWS_116:DLQ applies to async invocations only; auth_api is invoked synchronously by API Gateway
  #checkov:skip=CKV_AWS_173:Environment variables are resource IDs (CLIENT_ID, USER_POOL_ID), not secrets
  function_name    = "${var.name_prefix}-auth-api"
  role             = var.auth_api_role_arn
  runtime          = "nodejs22.x"
  handler          = "index.handler"
  filename         = local.auth_api_zip
  source_code_hash = try(filebase64sha256(local.auth_api_zip), null)
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      CLIENT_ID               = var.cognito_client_id
      USER_POOL_ID            = var.cognito_user_pool_id
      POWERTOOLS_SERVICE_NAME = "auth-api"
      LOG_LEVEL               = "INFO"
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [aws_cloudwatch_log_group.auth_api]
}

resource "aws_lambda_permission" "auth_api_apigw" {
  #checkov:skip=CKV_AWS_364:source_arn is scoped to this API Gateway execution ARN
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.public.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "classification_api" {
  #checkov:skip=CKV_AWS_158:KMS encryption for CW logs not required in dev
  name              = "/aws/lambda/${var.name_prefix}-classification-api"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "classification_api" {
  #checkov:skip=CKV_AWS_116:DLQ applies to async invocations only; classification_api is invoked synchronously by API Gateway
  #checkov:skip=CKV_AWS_173:Environment variables are resource IDs (JOBS_TABLE_NAME), not secrets
  function_name    = "${var.name_prefix}-classification-api"
  role             = var.classification_api_role_arn
  runtime          = "nodejs22.x"
  handler          = "index.handler"
  filename         = local.classification_api_zip
  source_code_hash = try(filebase64sha256(local.classification_api_zip), null)
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      JOBS_TABLE_NAME         = var.jobs_table_name
      POWERTOOLS_SERVICE_NAME = "classification-api"
      LOG_LEVEL               = "INFO"
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [aws_cloudwatch_log_group.classification_api]
}

resource "aws_lambda_permission" "classification_api_apigw" {
  #checkov:skip=CKV_AWS_364:source_arn is scoped to this API Gateway execution ARN
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.classification_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.public.execution_arn}/*/*"
}
