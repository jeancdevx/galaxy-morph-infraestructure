resource "aws_iam_role" "results_dispatcher" {
  name               = "${var.name_prefix}-results-dispatcher-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "emr_serverless_execution" {
  name               = "${var.name_prefix}-emr-serverless-execution-role"
  assume_role_policy = data.aws_iam_policy_document.emr_serverless_assume_role.json
}

resource "aws_iam_role" "sagemaker_execution" {
  name               = "${var.name_prefix}-sagemaker-execution-role"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume_role.json
}

resource "aws_iam_role" "msk_connect_execution" {
  name               = "${var.name_prefix}-msk-connect-execution-role"
  assume_role_policy = data.aws_iam_policy_document.msk_connect_assume_role.json
}

resource "aws_iam_role" "upload_api" {
  name               = "${var.name_prefix}-upload-api-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "ingestion_api" {
  name               = "${var.name_prefix}-ingestion-api-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "auth_api" {
  name               = "${var.name_prefix}-auth-api-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "classification_api" {
  name               = "${var.name_prefix}-classification-api-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "post_confirmation" {
  name               = "${var.name_prefix}-post-confirmation-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "post_confirmation_basic" {
  role       = aws_iam_role.post_confirmation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "post_confirmation" {
  statement {
    sid = "CognitoAddToGroup"

    actions = ["cognito-idp:AdminAddUserToGroup"]

    resources = [
      var.cognito_user_pool_id != "" ?
      "arn:aws:cognito-idp:${var.aws_region}:${var.aws_account_id}:userpool/${var.cognito_user_pool_id}" :
      "*"
    ]
  }
}

resource "aws_iam_policy" "post_confirmation" {
  name   = "${var.name_prefix}-post-confirmation-policy"
  policy = data.aws_iam_policy_document.post_confirmation.json
}

resource "aws_iam_role_policy_attachment" "post_confirmation" {
  role       = aws_iam_role.post_confirmation.name
  policy_arn = aws_iam_policy.post_confirmation.arn
}


