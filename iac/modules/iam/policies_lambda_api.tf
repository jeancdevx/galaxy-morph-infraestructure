data "aws_iam_policy_document" "lambda_api" {
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
    sid = "CognitoAuth"

    actions = [
      "cognito-idp:InitiateAuth",
      "cognito-idp:SignUp",
      "cognito-idp:ConfirmSignUp",
      "cognito-idp:ResendConfirmationCode",
    ]

    resources = [
      var.cognito_user_pool_id != "" ?
      "arn:aws:cognito-idp:${var.aws_region}:${var.aws_account_id}:userpool/${var.cognito_user_pool_id}" :
      "*"
    ]
  }

  statement {
    sid = "DynamoDBJobsQuery"

    actions = [
      "dynamodb:Query",
    ]

    resources = [
      local.jobs_table_arn,
      "${local.jobs_table_arn}/index/*",
    ]
  }
}

resource "aws_iam_policy" "lambda_api" {
  name   = "${var.name_prefix}-lambda-api-policy"
  policy = data.aws_iam_policy_document.lambda_api.json
}

resource "aws_iam_role_policy_attachment" "lambda_api" {
  role       = aws_iam_role.lambda_api.name
  policy_arn = aws_iam_policy.lambda_api.arn
}
