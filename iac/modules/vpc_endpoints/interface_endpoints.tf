resource "aws_vpc_endpoint" "sqs_interface" {
  count = var.enable_sqs_interface_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sqs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = var.endpoint_security_group_ids
  private_dns_enabled = var.enable_private_dns

  tags = {
    Name = "${var.name_prefix}-vpce-sqs-interface"
    Type = "interface"
  }
}

resource "aws_vpc_endpoint" "sagemaker_runtime_interface" {
  count = var.enable_sagemaker_runtime_interface_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sagemaker.runtime"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = var.endpoint_security_group_ids
  private_dns_enabled = var.enable_private_dns

  tags = {
    Name = "${var.name_prefix}-vpce-sagemaker-runtime-interface"
    Type = "interface"
  }
}
