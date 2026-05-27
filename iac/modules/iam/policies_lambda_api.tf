# auth_api: handles user authentication flows against Cognito. No DynamoDB access needed.
data "aws_iam_policy_document" "auth_api" {
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
}

resource "aws_iam_policy" "auth_api" {
  name   = "${var.name_prefix}-auth-api-policy"
  policy = data.aws_iam_policy_document.auth_api.json
}

resource "aws_iam_role_policy_attachment" "auth_api" {
  role       = aws_iam_role.auth_api.name
  policy_arn = aws_iam_policy.auth_api.arn
}

# classification_api: queries job records by clientId GSI. No Cognito access needed.
data "aws_iam_policy_document" "classification_api" {
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

resource "aws_iam_policy" "classification_api" {
  name   = "${var.name_prefix}-classification-api-policy"
  policy = data.aws_iam_policy_document.classification_api.json
}

resource "aws_iam_role_policy_attachment" "classification_api" {
  role       = aws_iam_role.classification_api.name
  policy_arn = aws_iam_policy.classification_api.arn
}

