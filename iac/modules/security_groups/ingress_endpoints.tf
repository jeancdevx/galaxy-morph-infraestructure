resource "aws_vpc_security_group_ingress_rule" "endpoints_from_lambda_private" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.lambda_private.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow Lambda private SG to connect to VPC Endpoints"
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_emr" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.emr.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow EMR SG to connect to VPC Endpoints"
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_msk_connect" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.msk_connect.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow MSK Connect SG to connect to VPC Endpoints"
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_sagemaker" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  referenced_security_group_id = aws_security_group.sagemaker_endpoint.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow SageMaker SG to connect to VPC Endpoints"
}
