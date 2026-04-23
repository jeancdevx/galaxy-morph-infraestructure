resource "aws_vpc_security_group_ingress_rule" "msk_from_lambda_private" {
  security_group_id            = aws_security_group.msk.id
  referenced_security_group_id = aws_security_group.lambda_private.id
  from_port                    = var.msk_port
  to_port                      = var.msk_port
  ip_protocol                  = "tcp"
  description                  = "Allow Lambda private SG to connect to MSK"
}

resource "aws_vpc_security_group_ingress_rule" "msk_from_emr" {
  security_group_id            = aws_security_group.msk.id
  referenced_security_group_id = aws_security_group.emr.id
  from_port                    = var.msk_port
  to_port                      = var.msk_port
  ip_protocol                  = "tcp"
  description                  = "Allow EMR SG to connect to MSK"
}

resource "aws_vpc_security_group_ingress_rule" "msk_from_msk_connect" {
  security_group_id            = aws_security_group.msk.id
  referenced_security_group_id = aws_security_group.msk_connect.id
  from_port                    = var.msk_port
  to_port                      = var.msk_port
  ip_protocol                  = "tcp"
  description                  = "Allow MSK Connect SG to connect to MSK"
}
