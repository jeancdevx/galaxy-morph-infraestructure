resource "aws_vpc_security_group_egress_rule" "lambda_private_all" {
  security_group_id = aws_security_group.lambda_private.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "emr_all" {
  security_group_id = aws_security_group.emr.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "msk_connect_all" {
  security_group_id = aws_security_group.msk_connect.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "msk_all" {
  security_group_id = aws_security_group.msk.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "sagemaker_endpoint_all" {
  security_group_id = aws_security_group.sagemaker_endpoint.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
