resource "aws_api_gateway_rest_api" "private" {
  name = "${var.name_prefix}-private-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${var.name_prefix}-cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.private.id
  type            = "COGNITO_USER_POOLS"
  identity_source = "method.request.header.Authorization"
  provider_arns   = [var.cognito_user_pool_arn]
}

resource "aws_api_gateway_resource" "upload" {
  rest_api_id = aws_api_gateway_rest_api.private.id
  parent_id   = aws_api_gateway_rest_api.private.root_resource_id
  path_part   = "upload"
}

resource "aws_api_gateway_resource" "upload_presigned" {
  rest_api_id = aws_api_gateway_rest_api.private.id
  parent_id   = aws_api_gateway_resource.upload.id
  path_part   = "presigned"
}

resource "aws_api_gateway_method" "upload_presigned_post" {
  rest_api_id   = aws_api_gateway_rest_api.private.id
  resource_id   = aws_api_gateway_resource.upload_presigned.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "upload_presigned_post" {
  rest_api_id             = aws_api_gateway_rest_api.private.id
  resource_id             = aws_api_gateway_resource.upload_presigned.id
  http_method             = aws_api_gateway_method.upload_presigned_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.upload_api.invoke_arn
}

resource "aws_api_gateway_resource" "classifications" {
  rest_api_id = aws_api_gateway_rest_api.private.id
  parent_id   = aws_api_gateway_rest_api.private.root_resource_id
  path_part   = "classifications"
}

resource "aws_api_gateway_method" "classifications_post" {
  rest_api_id   = aws_api_gateway_rest_api.private.id
  resource_id   = aws_api_gateway_resource.classifications.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "classifications_post" {
  rest_api_id             = aws_api_gateway_rest_api.private.id
  resource_id             = aws_api_gateway_resource.classifications.id
  http_method             = aws_api_gateway_method.classifications_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ingestion_api.invoke_arn
}

resource "aws_api_gateway_deployment" "private" {
  rest_api_id = aws_api_gateway_rest_api.private.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.upload_presigned.id,
      aws_api_gateway_resource.classifications.id,
      aws_api_gateway_method.upload_presigned_post.id,
      aws_api_gateway_method.classifications_post.id,
      aws_api_gateway_integration.upload_presigned_post.id,
      aws_api_gateway_integration.classifications_post.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.upload_presigned_post,
    aws_api_gateway_integration.classifications_post,
  ]
}

resource "aws_cloudwatch_log_group" "private_api_stage" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.private.id}/${var.stage_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_api_gateway_stage" "private" {
  deployment_id = aws_api_gateway_deployment.private.id
  rest_api_id   = aws_api_gateway_rest_api.private.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.private_api_stage.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      requestTime        = "$context.requestTime"
      httpMethod         = "$context.httpMethod"
      resourcePath       = "$context.resourcePath"
      status             = "$context.status"
      protocol           = "$context.protocol"
      responseLength     = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
      userAgent          = "$context.identity.userAgent"
    })
  }

  depends_on = [aws_cloudwatch_log_group.private_api_stage]
}
