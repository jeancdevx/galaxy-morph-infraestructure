data "aws_iam_policy_document" "kafka_setup" {
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
    sid = "MSKIAMClusterConnect"

    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:DescribeCluster",
    ]

    resources = [var.msk_cluster_arn]
  }

  statement {
    sid = "MSKIAMTopicManage"

    actions = [
      "kafka-cluster:CreateTopic",
      "kafka-cluster:DescribeTopic",
      "kafka-cluster:AlterTopic",
    ]

    # Wildcard suffix covers both galaxy.ingestion and galaxy.results under
    # the cluster's topic ARN namespace.
    resources = [var.msk_topic_arn_prefix]
  }
}

resource "aws_iam_policy" "kafka_setup" {
  name   = "${var.name_prefix}-kafka-setup-policy"
  policy = data.aws_iam_policy_document.kafka_setup.json
}

resource "aws_iam_role_policy_attachment" "kafka_setup" {
  role       = aws_iam_role.kafka_setup.name
  policy_arn = aws_iam_policy.kafka_setup.arn
}

resource "aws_iam_role_policy_attachment" "kafka_setup_vpc" {
  role       = aws_iam_role.kafka_setup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "kafka_setup_xray" {
  role       = aws_iam_role.kafka_setup.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}
