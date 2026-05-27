resource "aws_security_group" "lambda_private" {
  name_prefix = "${var.name_prefix}-lambda-private-"
  description = "Private Lambda functions security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-lambda-private"
    Tier = "private"
  }
}
