variable "aws_region" {
  description = "AWS region where production resources are provisioned"
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
  description = "Environment identifier"
  type        = string
  default     = "prod"
}
