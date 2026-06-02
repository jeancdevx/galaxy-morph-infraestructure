variable "name_prefix" {
  description = "Name prefix for all API Gateway and Lambda resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "Cognito User Pool ID — injected into Lambda env vars"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN — used as the REST API COGNITO_USER_POOLS authorizer provider"
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito User Pool Client ID — injected into auth Lambda env var"
  type        = string
}

variable "auth_api_role_arn" {
  description = "IAM role ARN for the auth-api Lambda function"
  type        = string
}

variable "classification_api_role_arn" {
  description = "IAM role ARN for the classification-api Lambda function"
  type        = string
}

variable "jobs_table_name" {
  description = "DynamoDB jobs table name — injected into classification API Lambda"
  type        = string
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "v1"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds (max 29 s for synchronous API Gateway calls)"
  type        = number
  default     = 29
}

variable "lambda_memory_size" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 256
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 14
}

variable "cors_allow_origins" {
  description = "List of allowed CORS origins. Used to populate CORS_ALLOW_ORIGINS in Lambda env vars so handlers can echo back the matching origin. OPTIONS preflight always returns * (Bearer-auth APIs do not need credentialed preflights)."
  type        = list(string)
  default     = ["*"]
}
