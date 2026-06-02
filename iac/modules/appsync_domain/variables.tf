variable "name_prefix" {
  description = "Prefix used for resource names and tags"
  type        = string
}

variable "appsync_api_id" {
  description = "AppSync GraphQL API ID to associate with the custom domain"
  type        = string
}

variable "appsync_api_arn" {
  description = "AppSync GraphQL API ARN used for WAF WebACL association"
  type        = string
}

variable "domain_name" {
  description = "Custom domain for AppSync (e.g. api.galaxymorph.com)"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN in the same region as AppSync (us-east-2)"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAFv2 REGIONAL WebACL to associate with the AppSync API"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID used to create the CNAME record"
  type        = string
}
