variable "name_prefix" {
  description = "Prefix used to name IAM roles and policies"
  type        = string
}

variable "aws_region" {
  description = "AWS region for ARNs and policy scoping"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID for policy resource scoping"
  type        = string
}

variable "jobs_table_name" {
  description = "DynamoDB jobs table name used by service roles"
  type        = string
  default     = "galaxy-morph-jobs"
}

variable "images_bucket_name" {
  description = "S3 bucket name for galaxy images"
  type        = string
  default     = "galaxy-morph-images"
}

variable "checkpoints_bucket_name" {
  description = "S3 bucket name for Spark checkpoints"
  type        = string
  default     = "galaxy-morph-checkpoints"
}

variable "models_bucket_name" {
  description = "S3 bucket name for model artifacts"
  type        = string
  default     = "galaxy-morph-models"
}

variable "raw_bucket_name" {
  description = "S3 bucket name for raw telescope data"
  type        = string
  default     = "galaxy-morph-raw"
}

variable "appsync_api_arn" {
  description = "AppSync API ARN used by results dispatcher"
  type        = string
  default     = "*"
}

variable "msk_cluster_arn" {
  description = "MSK cluster ARN used by streaming components"
  type        = string
  default     = "*"
}

variable "ingestion_queue_arn" {
  description = "SQS ingestion queue ARN used by MSK Connect"
  type        = string
  default     = "*"
}
