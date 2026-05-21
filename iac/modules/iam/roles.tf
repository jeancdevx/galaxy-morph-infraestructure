resource "aws_iam_role" "lambda_execution" {
  name               = "${var.name_prefix}-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "results_dispatcher" {
  name               = "${var.name_prefix}-results-dispatcher-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "emr_serverless_execution" {
  name               = "${var.name_prefix}-emr-serverless-execution-role"
  assume_role_policy = data.aws_iam_policy_document.emr_serverless_assume_role.json
}

resource "aws_iam_role" "sagemaker_execution" {
  name               = "${var.name_prefix}-sagemaker-execution-role"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume_role.json
}

resource "aws_iam_role" "msk_connect_execution" {
  name               = "${var.name_prefix}-msk-connect-execution-role"
  assume_role_policy = data.aws_iam_policy_document.msk_connect_assume_role.json
}

resource "aws_iam_role" "lambda_api" {
  name               = "${var.name_prefix}-lambda-api-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "post_confirmation" {
  name               = "${var.name_prefix}-post-confirmation-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "post_confirmation_basic" {
  role       = aws_iam_role.post_confirmation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "post_confirmation" {
  name = "${var.name_prefix}-post-confirmation-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "CognitoAddToGroup"
      Effect   = "Allow"
      Action   = "cognito-idp:AdminAddUserToGroup"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "post_confirmation" {
  role       = aws_iam_role.post_confirmation.name
  policy_arn = aws_iam_policy.post_confirmation.arn
}

resource "aws_iam_role" "lambda_private_api" {
  name               = "${var.name_prefix}-lambda-private-api-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_private_api" {
  name = "${var.name_prefix}-lambda-private-api-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3PresignedPut"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "arn:aws:s3:::${var.images_bucket_name}/galaxies/*"
      },
      {
        Sid    = "DynamoDBJobsWrite"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
        ]
        Resource = [
          local.jobs_table_arn,
          "${local.jobs_table_arn}/index/*",
        ]
      },
      {
        Sid    = "SQSEnqueue"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:SendMessageBatch",
        ]
        Resource = var.ingestion_queue_arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_private_api" {
  role       = aws_iam_role.lambda_private_api.name
  policy_arn = aws_iam_policy.lambda_private_api.arn
}

resource "aws_iam_role_policy_attachment" "lambda_private_api_basic" {
  role       = aws_iam_role.lambda_private_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_private_api_xray" {
  role       = aws_iam_role.lambda_private_api.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}
