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
    sid = "InvokeSageMakerEndpoint"

    actions = [
      "sagemaker:InvokeEndpoint",
    ]

    resources = ["*"]
  }

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
    sid = "CloudWatchLogs"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
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
