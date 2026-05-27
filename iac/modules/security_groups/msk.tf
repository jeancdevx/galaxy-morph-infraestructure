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
