variable "enable_connector" {
  description = "Whether to create the MSK Connect connector"
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Prefix used to name connector resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region used by the connector"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by MSK Connect workers"
  type        = list(string)
}

variable "msk_connect_security_group_id" {
  description = "Security group ID used by MSK Connect workers"
  type        = string
}

variable "msk_bootstrap_brokers_sasl_iam" {
  description = "MSK bootstrap brokers for IAM auth"
  type        = string
}

variable "service_execution_role_arn" {
  description = "IAM role ARN used by MSK Connect"
  type        = string
}

variable "custom_plugin_arn" {
  description = "MSK Connect custom plugin ARN for SQS Source connector"
  type        = string
  default     = null
  nullable    = true
}

variable "custom_plugin_revision" {
  description = "MSK Connect custom plugin revision"
  type        = number
  default     = null
  nullable    = true
}

variable "ingestion_queue_arn" {
  description = "SQS ingestion queue ARN consumed by the connector"
  type        = string
}

variable "ingestion_topic_name" {
  description = "Kafka topic where ingestion events are published"
  type        = string
  default     = "galaxy.ingestion"
}

variable "kafkaconnect_version" {
  description = "Kafka Connect runtime version"
  type        = string
  default     = "2.7.1"
}

variable "mcu_count" {
  description = "MCU count per worker for auto scaling capacity"
  type        = number
  default     = 1
}

variable "min_worker_count" {
  description = "Minimum worker count for connector autoscaling"
  type        = number
  default     = 2
}

variable "max_worker_count" {
  description = "Maximum worker count for connector autoscaling"
  type        = number
  default     = 10
}

variable "tasks_max" {
  description = "Maximum connector tasks"
  type        = number
  default     = 16
}

variable "cloudwatch_log_retention_days" {
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
