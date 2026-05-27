resource "aws_iam_role" "apigw_cloudwatch" {
  name = "${var.name_prefix}-apigw-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "apigateway.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apigw_cloudwatch" {
  role       = aws_iam_role.apigw_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch.arn

  depends_on = [aws_iam_role_policy_attachment.apigw_cloudwatch]
}

resource "aws_cloudwatch_log_group" "public_api_stage" {
  #checkov:skip=CKV_AWS_158:KMS encryption for CW logs not required in dev
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.public.id}/${var.stage_name}"
  retention_in_days = var.log_retention_days
}
