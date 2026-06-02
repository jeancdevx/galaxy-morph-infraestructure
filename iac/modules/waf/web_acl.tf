resource "aws_wafv2_web_acl" "this" {
  #checkov:skip=CKV2_AWS_31:WAF logging configured via aws_wafv2_web_acl_logging_configuration
  name  = "${var.name_prefix}-waf-${lower(var.scope)}"
  scope = var.scope

  default_action {
    allow {}
  }

  # Priority 5 — block requests that do not carry the CloudFront origin-verify secret.
  dynamic "rule" {
    for_each = var.origin_verify_header_value != "" ? [1] : []
    content {
      name     = "RequireOriginVerifyHeader"
      priority = 5

      action {
        block {}
      }

      statement {
        not_statement {
          statement {
            byte_match_statement {
              search_string = var.origin_verify_header_value

              field_to_match {
                single_header { name = "x-origin-verify" }
              }

              text_transformation {
                priority = 0
                type     = "NONE"
              }

              positional_constraint = "EXACTLY"
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name_prefix}-origin-verify"
        sampled_requests_enabled   = true
      }
    }
  }

  # Priority 10 — block requests from IPs with poor reputation (scrapers, botnets, TOR)
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  # Priority 20 — OWASP Top 10 core rules (SQLi, XSS, LFI, etc.)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # Priority 30 — known bad inputs (Log4Shell, SSRF probes, malformed request bodies)
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # Priority 40 — per-IP rate limit to mitigate brute-force and DoS attempts
  rule {
    name     = "RateLimitPerIP"
    priority = 40

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf-${lower(var.scope)}"
    sampled_requests_enabled   = true
  }

  tags = {
    Name  = "${var.name_prefix}-waf-${lower(var.scope)}"
    Scope = var.scope
  }
}
