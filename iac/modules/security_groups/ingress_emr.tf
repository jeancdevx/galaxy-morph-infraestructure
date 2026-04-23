resource "aws_vpc_security_group_ingress_rule" "emr_self_all" {
  security_group_id            = aws_security_group.emr.id
  referenced_security_group_id = aws_security_group.emr.id
  ip_protocol                  = "-1"
  description                  = "Allow EMR worker-to-worker communication"
}
