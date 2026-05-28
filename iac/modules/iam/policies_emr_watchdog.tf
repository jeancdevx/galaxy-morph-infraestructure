data "aws_iam_policy_document" "emr_watchdog" {
  statement {
    sid = "CloudWatchLogs"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${var.name_prefix}-emr-job-launcher:*",
      "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${var.name_prefix}-emr-job-watchdog:*",
    ]
  }

  statement {
    sid = "EMRStartJobRun"

    actions = [
      "emr-serverless:StartJobRun",
      "emr-serverless:TagResource",
    ]

    resources = [var.emr_application_arn]
  }

  statement {
    sid = "PassEMRExecutionRole"

    actions = ["iam:PassRole"]

    resources = [
      "arn:aws:iam::${var.aws_account_id}:role/${var.name_prefix}-emr-serverless-execution-role",
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["emr-serverless.amazonaws.com"]
    }
  }

  statement {
    sid = "SSMJobRunId"

    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter",
    ]

    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/${var.name_prefix}/emr/*",
    ]
  }
}

resource "aws_iam_policy" "emr_watchdog" {
  name   = "${var.name_prefix}-emr-watchdog-policy"
  policy = data.aws_iam_policy_document.emr_watchdog.json
}

resource "aws_iam_role_policy_attachment" "emr_watchdog" {
  role       = aws_iam_role.emr_watchdog.name
  policy_arn = aws_iam_policy.emr_watchdog.arn
}

resource "aws_iam_role_policy_attachment" "emr_watchdog_xray" {
  role       = aws_iam_role.emr_watchdog.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy_attachment" "emr_watchdog_basic" {
  role       = aws_iam_role.emr_watchdog.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
