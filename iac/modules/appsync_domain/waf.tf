resource "aws_wafv2_web_acl_association" "appsync" {
  resource_arn = var.appsync_api_arn
  web_acl_arn  = var.waf_web_acl_arn
}
