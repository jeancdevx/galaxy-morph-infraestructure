variable "name_prefix" {
  description = "Prefix used for resource names and tags"
  type        = string
}

variable "spa_bucket_id" {
  description = "S3 bucket name of the SPA frontend bucket"
  type        = string
}

variable "spa_bucket_arn" {
  description = "ARN of the SPA frontend S3 bucket"
  type        = string
}

variable "images_bucket_id" {
  description = "S3 bucket name of the galaxy images bucket"
  type        = string
}

variable "images_bucket_arn" {
  description = "ARN of the galaxy images S3 bucket"
  type        = string
}

variable "api_gateway_invoke_url" {
  description = "Full invoke URL from API Gateway (e.g. https://xxx.execute-api.us-east-2.amazonaws.com/v1)"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN — must be in us-east-1 (CloudFront requirement)"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAFv2 WebACL with CLOUDFRONT scope (created in us-east-1)"
  type        = string
}

variable "origin_verify_secret" {
  description = "Secret value injected as X-Origin-Verify header on requests to API Gateway. The API Gateway WAF blocks requests missing this header, preventing direct access bypass."
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Primary domain for the CloudFront distribution (e.g. galaxymorph.com)"
  type        = string
}

variable "aliases" {
  description = "Additional domain aliases served by CloudFront (e.g. [\"www.galaxymorph.com\"])"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID used to create A alias records"
  type        = string
}

variable "price_class" {
  description = "CloudFront price class: PriceClass_100 (US/EU), PriceClass_200 (+Asia/ME), PriceClass_All"
  type        = string
  default     = "PriceClass_100"
}

variable "log_retention_days" {
  description = "Days to retain CloudFront access logs in S3 before expiration"
  type        = number
  default     = 90
}
