data "aws_region" "current" {}

locals {
  _api_no_scheme  = trimprefix(var.api_gateway_invoke_url, "https://")
  api_origin_host = split("/", local._api_no_scheme)[0]
}

resource "aws_cloudfront_distribution" "this" {
  #checkov:skip=CKV2_AWS_32:Response headers policy managed at application level
  #checkov:skip=CKV_AWS_310:Origin failover not required for dev
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.name_prefix} — SPA, images, API"
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = concat([var.domain_name], var.aliases)
  web_acl_id          = var.waf_web_acl_arn

  origin {
    origin_id                = "spa"
    domain_name              = "${var.spa_bucket_id}.s3.${data.aws_region.current.region}.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.spa.id
  }

  origin {
    origin_id                = "images"
    domain_name              = "${var.images_bucket_id}.s3.${data.aws_region.current.region}.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.images.id
  }

  origin {
    origin_id   = "api"
    domain_name = local.api_origin_host

    # Secret header — API Gateway WAF blocks any request missing this header,
    # enforcing that all traffic goes through CloudFront.
    custom_header {
      name  = "x-origin-verify"
      value = var.origin_verify_secret
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default: SPA assets from S3 (cache-busted by content hash, long TTL)
  default_cache_behavior {
    target_origin_id       = "spa"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 86400    # 24 h
    max_ttl     = 31536000 # 1 year
  }

  # /images/*: galaxy images from S3
  ordered_cache_behavior {
    path_pattern           = "/images/*"
    target_origin_id       = "images"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 604800   # 7 days
    max_ttl     = 31536000 # 1 year
  }

  # /api/v1/*: API Gateway — no caching, forward auth headers and query strings.
  # A CloudFront Function rewrites /api/v1/x → /v1/x at the viewer-request stage.
  ordered_cache_behavior {
    path_pattern           = "/api/v1/*"
    target_origin_id       = "api"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = false

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Origin", "Accept", "Content-Type"]
      cookies { forward = "none" }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.api_rewrite.arn
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # SPA client-side routing
  # S3 returns 403 for missing paths; remap to index.html so the SPA router takes over.
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  # TLS
  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Access logs
  logging_config {
    include_cookies = false
    bucket          = "${aws_s3_bucket.logs.id}.s3.amazonaws.com"
    prefix          = "cloudfront/"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "${var.name_prefix}-cloudfront"
  }

  depends_on = [aws_s3_bucket_acl.logs]
}
