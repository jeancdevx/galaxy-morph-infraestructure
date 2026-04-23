data "aws_iam_policy_document" "msk_connect_execution" {
  statement {
    sid = "MSKIAMAuth"

    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:DescribeCluster",
      "kafka-cluster:DescribeTopic",
      "kafka-cluster:ReadData",
      "kafka-cluster:WriteData",
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DescribeGroup",
    ]

    resources = [var.msk_cluster_arn]
  }

  statement {
    sid = "SQSRead"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ChangeMessageVisibility",
    ]

    resources = ["*"]
  }

  statement {
    sid = "CloudWatchLogs"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "msk_connect_execution" {
  name   = "${var.name_prefix}-msk-connect-execution-policy"
  policy = data.aws_iam_policy_document.msk_connect_execution.json
}

resource "aws_iam_role_policy_attachment" "msk_connect_execution" {
  role       = aws_iam_role.msk_connect_execution.name
  policy_arn = aws_iam_policy.msk_connect_execution.arn
}
