variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "results_dispatcher_role_arn" {
  description = "IAM role ARN for the results-dispatcher Lambda"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Lambda VPC config"
  type        = list(string)
}

variable "lambda_private_sg_id" {
  description = "Security group ID that allows MSK access"
  type        = string
}

variable "jobs_table_name" {
  description = "DynamoDB jobs table name"
  type        = string
}

variable "appsync_graphql_url" {
  description = "AppSync GraphQL endpoint URL"
  type        = string
}

variable "msk_cluster_arn" {
  description = "MSK Serverless cluster ARN for event source mapping"
  type        = string
}

variable "results_topic_name" {
  description = "Kafka topic name for classification results"
  type        = string
  default     = "galaxy.results"
}

variable "dispatcher_dlq_arn" {
  description = "Optional SQS/SNS ARN for failed-batch destination"
  type        = string
  default     = null
  nullable    = true
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "lambda_memory_size" {
  description = "Lambda memory allocation in MB"
  type        = number
  default     = 256
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}
