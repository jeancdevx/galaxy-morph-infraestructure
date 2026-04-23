resource "aws_vpc_security_group_ingress_rule" "sagemaker_from_emr_https" {
  security_group_id            = aws_security_group.sagemaker_endpoint.id
  referenced_security_group_id = aws_security_group.emr.id
  from_port                    = var.sagemaker_https_port
  to_port                      = var.sagemaker_https_port
  ip_protocol                  = "tcp"
  description                  = "Allow EMR SG to invoke SageMaker endpoint over HTTPS"
}
