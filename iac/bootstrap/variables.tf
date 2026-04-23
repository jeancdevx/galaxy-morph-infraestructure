variable "aws_region" {
  description = "AWS region where bootstrap resources are provisioned"
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "AWS shared config profile name (useful for AWS SSO)"
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project identifier used in naming and tagging"
  type        = string
  default     = "galaxy-morph"
}

variable "environment" {
  description = "Environment identifier for bootstrap resources"
  type        = string
  default     = "bootstrap"
}

variable "state_bucket_name_override" {
  description = "Optional explicit S3 bucket name for Terraform state"
  type        = string
  default     = null
}

variable "state_lock_table_name" {
  description = "DynamoDB table name used for Terraform state locking"
  type        = string
  default     = "galaxy-morph-terraform-locks"
}
