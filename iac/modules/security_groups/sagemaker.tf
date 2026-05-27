resource "aws_security_group" "sagemaker_endpoint" {
  name_prefix = "${var.name_prefix}-sagemaker-endpoint-"
  description = "SageMaker endpoint security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-sagemaker-endpoint"
    Tier = "private"
  }
}
