data "aws_iam_policy_document" "sagemaker_execution" {
  statement {
    sid = "ModelArtifactsRead"

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
    sid = "ImagesRead"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      local.images_bucket_arn,
      local.images_bucket_all_arn,
    ]
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

  statement {
    sid = "ECRRead"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "sagemaker_execution" {
  name   = "${var.name_prefix}-sagemaker-execution-policy"
  policy = data.aws_iam_policy_document.sagemaker_execution.json
}

resource "aws_iam_role_policy_attachment" "sagemaker_execution" {
  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = aws_iam_policy.sagemaker_execution.arn
}
