data "aws_iam_policy_document" "results_dispatcher" {
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
    sid = "DynamoDBJobsUpdate"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]

    resources = [local.jobs_table_arn]
  }

  statement {
    sid = "AppSyncGraphQLMutation"

    actions = [
      "appsync:GraphQL",
    ]

    resources = [var.appsync_api_arn]
  }
}

resource "aws_iam_policy" "results_dispatcher" {
  name   = "${var.name_prefix}-results-dispatcher-policy"
  policy = data.aws_iam_policy_document.results_dispatcher.json
}

resource "aws_iam_role_policy_attachment" "results_dispatcher" {
  role       = aws_iam_role.results_dispatcher.name
  policy_arn = aws_iam_policy.results_dispatcher.arn
}

resource "aws_iam_role_policy_attachment" "results_dispatcher_vpc" {
  role       = aws_iam_role.results_dispatcher.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
