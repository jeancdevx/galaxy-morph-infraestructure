# CloudWatch log group for AppSync
resource "aws_cloudwatch_log_group" "appsync" {
  #checkov:skip=CKV_AWS_158:KMS encryption for CW logs not required in dev
  name              = "/aws/appsync/apis/${aws_appsync_graphql_api.main.id}"
  retention_in_days = var.log_retention_days
}

# IAM role for AppSync → CloudWatch
resource "aws_iam_role" "appsync_logging" {
  name = "${var.name_prefix}-appsync-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "appsync.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "appsync_logging" {
  role       = aws_iam_role.appsync_logging.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppSyncPushToCloudWatchLogs"
}
