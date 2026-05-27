resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.name_prefix}-vpc-endpoints-"
  description = "Security group for VPC Endpoints"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-vpc-endpoints"
    Tier = "private"
  }
}
