data "aws_iam_policy_document" "lambda_runtime" {
  statement {
    sid = "CloudWatchLogs"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    sid = "S3ImagesReadWrite"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [local.images_bucket_all_arn]
  }

  statement {
    sid = "DynamoDBJobsReadWrite"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]

    resources = [local.jobs_table_arn]
  }

  statement {
    sid = "SQSQueueAccess"

    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_runtime" {
  name   = "${var.name_prefix}-lambda-runtime-policy"
  policy = data.aws_iam_policy_document.lambda_runtime.json
}

resource "aws_iam_role_policy_attachment" "lambda_runtime" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_runtime.arn
}

resource "aws_iam_role_policy_attachment" "lambda_managed_vpc" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
