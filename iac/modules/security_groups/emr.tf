resource "aws_security_group" "emr" {
  name_prefix = "${var.name_prefix}-emr-"
  description = "EMR Serverless security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-emr"
    Tier = "private"
  }
}
