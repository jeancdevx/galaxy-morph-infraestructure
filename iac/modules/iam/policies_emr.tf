data "aws_iam_policy_document" "emr_serverless" {
  statement {
    sid = "ReadWriteImagesBucket"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    resources = [
      local.images_bucket_arn,
      local.images_bucket_all_arn,
    ]
  }

  statement {
    sid = "ReadWriteCheckpointsBucket"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    resources = [
      local.checkpoints_bucket_arn,
      local.checkpoints_all_arn,
    ]
  }

  statement {
    sid = "ReadModelsBucket"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      local.models_bucket_arn,
      local.models_bucket_all_arn,
    ]
  }

  statement {
    sid = "MSKIAMCluster"

    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:DescribeCluster",
    ]

    resources = [var.msk_cluster_arn]
  }

  statement {
    sid = "MSKIAMTopics"

    actions = [
      "kafka-cluster:DescribeTopic",
      "kafka-cluster:ReadData",
      "kafka-cluster:WriteData",
      "kafka-cluster:CreateTopic",
    ]

    resources = [var.msk_topic_arn_prefix]
  }

  statement {
    sid = "MSKIAMGroups"

    actions = [
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DescribeGroup",
    ]

    resources = [var.msk_group_arn_prefix]
  }

  statement {
    sid = "CloudWatchLogsWrite"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = local.emr_log_arns
  }

  statement {
    sid = "CloudWatchLogsDescribe"

    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    # logs:DescribeLogGroups and logs:DescribeLogStreams are called by EMR
    # Serverless at the account level to validate the logging destination
    # before log groups exist. These actions do not support resource-level
    # IAM scoping in this context (AWS API limitation).
    resources = ["*"]
  }

  statement {
    sid = "SageMakerInvoke"

    actions = [
      "sagemaker:InvokeEndpoint",
    ]

    resources = [var.sagemaker_endpoint_arn]
  }
}

resource "aws_iam_policy" "emr_serverless" {
  name   = "${var.name_prefix}-emr-serverless-policy"
  policy = data.aws_iam_policy_document.emr_serverless.json
}

resource "aws_iam_role_policy_attachment" "emr_serverless" {
  role       = aws_iam_role.emr_serverless_execution.name
  policy_arn = aws_iam_policy.emr_serverless.arn
}
