variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID for the authorizer"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN for the authorizer provider_arns"
  type        = string
}

variable "upload_api_role_arn" {
  description = "IAM role ARN for the upload-api Lambda function"
  type        = string
}

variable "ingestion_api_role_arn" {
  description = "IAM role ARN for the ingestion-api Lambda function"
  type        = string
}

variable "images_bucket_name" {
  description = "S3 bucket name where galaxy images are uploaded"
  type        = string
}

variable "jobs_table_name" {
  description = "DynamoDB jobs table name"
  type        = string
}

variable "ingestion_queue_url" {
  description = "SQS ingestion queue URL"
  type        = string
}

variable "stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
  default     = "v1"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 29
}

variable "lambda_memory_size" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 256
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}
