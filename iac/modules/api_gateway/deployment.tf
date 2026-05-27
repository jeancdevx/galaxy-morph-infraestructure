resource "aws_api_gateway_deployment" "public" {
  rest_api_id = aws_api_gateway_rest_api.public.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.auth_signup.id,
      aws_api_gateway_resource.auth_signin.id,
      aws_api_gateway_resource.classifications_history.id,
      aws_api_gateway_method.signup_post.id,
      aws_api_gateway_method.signin_post.id,
      aws_api_gateway_method.history_get.id,
      aws_api_gateway_integration.signup_post.id,
      aws_api_gateway_integration.signin_post.id,
      aws_api_gateway_integration.history_get.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "public" {
  deployment_id = aws_api_gateway_deployment.public.id
  rest_api_id   = aws_api_gateway_rest_api.public.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.public_api_stage.arn
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

  depends_on = [
    aws_cloudwatch_log_group.public_api_stage,
    aws_api_gateway_account.main,
  ]
}
