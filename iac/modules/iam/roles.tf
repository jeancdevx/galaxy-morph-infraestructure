resource "aws_iam_role" "lambda_execution" {
  name               = "${var.name_prefix}-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

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
