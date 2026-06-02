variable "name_prefix" {
  description = "Prefix used for resource names and tags"
  type        = string
}

variable "scope" {
  description = "Scope of the WebACL: CLOUDFRONT (us-east-1) or REGIONAL (any region)"
  type        = string

  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "scope must be CLOUDFRONT or REGIONAL"
  }
}

variable "rate_limit" {
  description = "Maximum number of requests from a single IP in a 5-minute window before blocking"
  type        = number
  default     = 2000
}

variable "log_retention_days" {
  description = "Retention period in days for WAF logs stored in CloudWatch"
  type        = number
  default     = 14
}

variable "origin_verify_header_value" {
  description = "When non-empty, adds a rule that blocks requests missing the X-Origin-Verify header with this exact value. Used to enforce CloudFront-only access to API Gateway."
  type        = string
  default     = ""
  sensitive   = true
}
