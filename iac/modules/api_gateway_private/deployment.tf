resource "aws_cloudwatch_log_group" "private_api_stage" {
  #checkov:skip=CKV_AWS_158:KMS encryption for CW logs not required in dev
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.private.id}/${var.stage_name}"
  retention_in_days = var.log_retention_days
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

resource "aws_api_gateway_stage" "private" {
  #checkov:skip=CKV_AWS_120:Stage-level caching has per-GB cost; not enabled in dev
  #checkov:skip=CKV2_AWS_77:WAF association planned for Q12
  #checkov:skip=CKV2_AWS_78:WAF association planned for Q12
  deployment_id        = aws_api_gateway_deployment.private.id
  rest_api_id          = aws_api_gateway_rest_api.private.id
  stage_name           = var.stage_name
  xray_tracing_enabled = true

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
