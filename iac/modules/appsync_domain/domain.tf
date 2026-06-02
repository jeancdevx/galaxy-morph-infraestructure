resource "aws_appsync_domain_name" "this" {
  domain_name     = var.domain_name
  certificate_arn = var.certificate_arn

  description = "${var.name_prefix} AppSync custom domain"
}

resource "aws_appsync_domain_name_api_association" "this" {
  domain_name = aws_appsync_domain_name.this.domain_name
  api_id      = var.appsync_api_id
}
