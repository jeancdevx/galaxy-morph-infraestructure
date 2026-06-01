# WAFv2 rules must be inline in aws_wafv2_web_acl — no separate rule resources exist.
# Rule priorities: lower number = evaluated first.
#   10  AWSManagedRulesAmazonIpReputationList  (blocks known bad IPs)
#   20  AWSManagedRulesCommonRuleSet            (OWASP Top 10 core rules)
#   30  AWSManagedRulesKnownBadInputsRuleSet    (log4j, SSRF, etc.)
#   40  RateLimitPerIP                          (var.rate_limit req / 5 min)
#
# All rules are defined inline in web_acl.tf.
