variable "name_prefix" {
  description = "Prefix used for naming user pool and groups"
  type        = string
}
variable "app_email_subject" {
  description = "Subject for email verification messages"
  type        = string
  default     = "galaxy-morph"
}

variable "aws_region" {
  description = "AWS region for ARN construction"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID for ARN construction"
  type        = string
}

variable "post_confirmation_role_arn" {
  description = "IAM role ARN for the Post Confirmation Lambda trigger"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days for the Post Confirmation Lambda"
  type        = number
  default     = 14
}
