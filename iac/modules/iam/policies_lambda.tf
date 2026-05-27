# upload_api: generates S3 presigned PutObject URLs. No DynamoDB or SQS access needed.
data "aws_iam_policy_document" "upload_api" {
  statement {
    sid = "CloudWatchLogs"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = local.lambda_log_arns
  }

  statement {
    sid = "S3PresignedPut"

    actions = ["s3:PutObject"]

    resources = ["arn:aws:s3:::${var.images_bucket_name}/galaxies/*"]
  }
}

resource "aws_iam_policy" "upload_api" {
  name   = "${var.name_prefix}-upload-api-policy"
  policy = data.aws_iam_policy_document.upload_api.json
}

resource "aws_iam_role_policy_attachment" "upload_api" {
  role       = aws_iam_role.upload_api.name
  policy_arn = aws_iam_policy.upload_api.arn
}

resource "aws_iam_role_policy_attachment" "upload_api_xray" {
  role       = aws_iam_role.upload_api.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# ingestion_api: enforces daily quota (UpdateItem with ConditionExpression),
# creates job records (PutItem), and enqueues classification tasks (SQS SendMessage).
# No S3 access needed — images are uploaded directly by the client via presigned URL.
data "aws_iam_policy_document" "ingestion_api" {
  statement {
    sid = "CloudWatchLogs"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = local.lambda_log_arns
  }

  statement {
    sid = "DynamoDBJobsWrite"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
    ]

    resources = [local.jobs_table_arn]
  }

  statement {
    sid = "SQSEnqueue"

    actions = [
      "sqs:SendMessage",
      "sqs:SendMessageBatch",
    ]

    resources = [var.ingestion_queue_arn]
  }
}

resource "aws_iam_policy" "ingestion_api" {
  name   = "${var.name_prefix}-ingestion-api-policy"
  policy = data.aws_iam_policy_document.ingestion_api.json
}

resource "aws_iam_role_policy_attachment" "ingestion_api" {
  role       = aws_iam_role.ingestion_api.name
  policy_arn = aws_iam_policy.ingestion_api.arn
}

resource "aws_iam_role_policy_attachment" "ingestion_api_xray" {
  role       = aws_iam_role.ingestion_api.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

