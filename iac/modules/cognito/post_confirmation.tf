locals {
  post_confirmation_zip = "${path.module}/../../../services/lambdas/post_confirmation/dist/function.zip"
}

resource "aws_cloudwatch_log_group" "post_confirmation" {
  #checkov:skip=CKV_AWS_158:KMS encryption for CW logs not required in dev
  name              = "/aws/lambda/${var.name_prefix}-post-confirmation"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "post_confirmation" {
  #checkov:skip=CKV_AWS_116:DLQ applies to async invocations only; post_confirmation is invoked synchronously by Cognito
  #checkov:skip=CKV_AWS_173:Environment variables are service config (POWERTOOLS_SERVICE_NAME, LOG_LEVEL), not secrets
  function_name = "${var.name_prefix}-post-confirmation"
  role          = var.post_confirmation_role_arn
  runtime       = "nodejs22.x"
  handler       = "index.handler"
  timeout       = 10
  memory_size   = 128

  filename         = local.post_confirmation_zip
  source_code_hash = try(filebase64sha256(local.post_confirmation_zip), null)

  environment {
    variables = {
      POWERTOOLS_SERVICE_NAME = "post-confirmation"
      LOG_LEVEL               = "INFO"
    }
  }

  depends_on = [aws_cloudwatch_log_group.post_confirmation]
}

# Allow Cognito to invoke this Lambda
resource "aws_lambda_permission" "cognito_post_confirmation" {
  #checkov:skip=CKV_AWS_364:source_arn is scoped to the Cognito user pool ARN
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = "arn:aws:cognito-idp:${var.aws_region}:${var.aws_account_id}:userpool/*"
}
