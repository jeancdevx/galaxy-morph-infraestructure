variable "name_prefix" {
  description = "Prefix used to name data layer resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the resources will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for MSK Serverless networking"
  type        = list(string)
}

variable "msk_security_group_id" {
  description = "Security group ID attached to MSK Serverless"
  type        = string
}

variable "jobs_table_name" {
  description = "DynamoDB table name for jobs metadata"
  type        = string
  default     = "galaxy-morph-jobs"
}

variable "jobs_table_hash_key" {
  description = "DynamoDB partition key attribute name"
  type        = string
  default     = "pk"
}

variable "jobs_table_range_key" {
  description = "DynamoDB sort key attribute name"
  type        = string
  default     = "sk"
}

variable "enable_point_in_time_recovery" {
  description = "Enable PITR on jobs DynamoDB table"
  type        = bool
  default     = true
}

variable "enable_ttl" {
  description = "Enable TTL on jobs table for auto-cleanup of old records"
  type        = bool
  default     = true
}

variable "enable_gsi_client_status" {
  description = "Enable GSI clientId-status-index for querying jobs by scientist"
  type        = bool
  default     = true
}

variable "ingestion_queue_name" {
  description = "SQS queue name for ingestion events"
  type        = string
  default     = "galaxy-morph-ingestion"
}

variable "ingestion_dlq_name" {
  description = "SQS dead-letter queue name for ingestion failures"
  type        = string
  default     = "galaxy-morph-ingestion-dlq"
}

variable "ingestion_queue_visibility_timeout_seconds" {
  description = "Visibility timeout in seconds for ingestion queue"
  type        = number
  default     = 120
}

variable "ingestion_queue_message_retention_seconds" {
  description = "Message retention in seconds for ingestion queue"
  type        = number
  default     = 345600
}

variable "ingestion_queue_max_receive_count" {
  description = "Max receive count before moving messages to DLQ"
  type        = number
  default     = 5
}

variable "msk_cluster_name" {
  description = "MSK Serverless cluster name"
  type        = string
  default     = null
  nullable    = true
}

variable "enable_msk_connect_connector" {
  description = "Whether to provision the MSK Connect SQS source connector"
  type        = bool
  default     = false
}

variable "msk_connect_security_group_id" {
  description = "Security group ID used by MSK Connect workers"
  type        = string
  default     = null
  nullable    = true
}

variable "msk_connect_execution_role_arn" {
  description = "IAM role ARN used by MSK Connect service"
  type        = string
  default     = null
  nullable    = true
}

variable "msk_connect_custom_plugin_arn" {
  description = "MSK Connect custom plugin ARN for SQS Source connector"
  type        = string
  default     = null
  nullable    = true
}

variable "msk_connect_custom_plugin_revision" {
  description = "MSK Connect custom plugin revision"
  type        = number
  default     = null
  nullable    = true
}

variable "ingestion_topic_name" {
  description = "Kafka topic where ingestion events are published"
  type        = string
  default     = "galaxy.ingestion"
}

variable "msk_connect_kafkaconnect_version" {
  description = "Kafka Connect runtime version"
  type        = string
  default     = "2.7.1"
}

variable "msk_connect_mcu_count" {
  description = "MCU count per worker for auto scaling capacity"
  type        = number
  default     = 1
}

variable "msk_connect_min_worker_count" {
  description = "Minimum worker count for connector autoscaling"
  type        = number
  default     = 2
}

variable "msk_connect_max_worker_count" {
  description = "Maximum worker count for connector autoscaling"
  type        = number
  default     = 10
}

variable "msk_connect_tasks_max" {
  description = "Maximum connector tasks"
  type        = number
  default     = 16
}

variable "msk_connect_log_retention_days" {
  description = "CloudWatch log retention in days for connector logs"
  type        = number
  default     = 14
}

variable "raw_bucket_name" {
  description = "Name of the raw bucket to store plugins"
  type        = string
}

variable "raw_bucket_arn" {
  description = "ARN of the raw bucket to store plugins"
  type        = string
}

variable "kafka_ui_execution_role_arn" {
  description = "IAM role ARN for Kafka UI ECS Execution"
  type        = string
}

variable "kafka_ui_task_role_arn" {
  description = "IAM role ARN for Kafka UI ECS Task"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for Kafka UI Fargate task"
  type        = list(string)
}
