resource "aws_security_group" "lambda_private" {
  name_prefix = "${var.name_prefix}-lambda-private-"
  description = "Private Lambda functions security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-lambda-private"
    Tier = "private"
  }
}

resource "aws_security_group" "emr" {
  name_prefix = "${var.name_prefix}-emr-"
  description = "EMR Serverless security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-emr"
    Tier = "private"
  }
}

resource "aws_security_group" "msk_connect" {
  name_prefix = "${var.name_prefix}-msk-connect-"
  description = "MSK Connect workers security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-msk-connect"
    Tier = "private"
  }
}

resource "aws_security_group" "msk" {
  name_prefix = "${var.name_prefix}-msk-"
  description = "MSK Serverless security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-msk"
    Tier = "private"
  }
}

resource "aws_security_group" "sagemaker_endpoint" {
  name_prefix = "${var.name_prefix}-sagemaker-endpoint-"
  description = "SageMaker endpoint security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-sagemaker-endpoint"
    Tier = "private"
  }
}

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.name_prefix}-vpc-endpoints-"
  description = "Security group for VPC Endpoints"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-vpc-endpoints"
    Tier = "private"
  }
}
