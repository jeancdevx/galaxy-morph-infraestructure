variable "name_prefix" {
  description = "Prefix for all AppSync resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID for default authentication"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}
