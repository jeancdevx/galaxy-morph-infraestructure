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

resource "aws_iam_role" "lambda_api" {
  name               = "${var.name_prefix}-lambda-api-role"
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

resource "aws_iam_policy" "post_confirmation" {
  name = "${var.name_prefix}-post-confirmation-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "CognitoAddToGroup"
      Effect   = "Allow"
      Action   = "cognito-idp:AdminAddUserToGroup"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "post_confirmation" {
  role       = aws_iam_role.post_confirmation.name
  policy_arn = aws_iam_policy.post_confirmation.arn
}
