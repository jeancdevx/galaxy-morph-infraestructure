resource "aws_route53_record" "appsync" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_appsync_domain_name.this.appsync_domain_name
    zone_id                = aws_appsync_domain_name.this.hosted_zone_id
    evaluate_target_health = false
  }
}
