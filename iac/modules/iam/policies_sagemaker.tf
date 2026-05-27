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

    resources = local.sagemaker_log_arns
  }

  statement {
    sid = "ECRAuthToken"

    actions = [
      "ecr:GetAuthorizationToken",
    ]

    # ecr:GetAuthorizationToken issues an account-level auth token and does not
    # support resource-level IAM permissions (AWS API limitation).
    resources = ["*"]
  }

  statement {
    sid = "ECRImagePull"

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
    ]

    resources = [var.ecr_repository_arn]
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
