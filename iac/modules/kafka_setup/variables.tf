variable "name_prefix" {
  description = "Prefix used for all resource names"
  type        = string
}

variable "execution_role_arn" {
  description = "IAM role ARN for the kafka_setup Lambda execution"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the Lambda VPC config"
  type        = list(string)
}

variable "lambda_private_sg_id" {
  description = "Security group ID that allows outbound access to MSK port 9098"
  type        = string
}

variable "kafka_bootstrap_servers" {
  description = "MSK Serverless bootstrap broker string (SASL/IAM, port 9098)"
  type        = string
}

variable "ingestion_topic_name" {
  description = "Name of the Kafka ingestion topic to create"
  type        = string
  default     = "galaxy.ingestion"
}

variable "results_topic_name" {
  description = "Name of the Kafka results topic to create"
  type        = string
  default     = "galaxy.results"
}

variable "topic_partitions" {
  description = "Number of partitions per topic"
  type        = number
  default     = 24
}

variable "topic_replication_factor" {
  description = "Replication factor for topics (MSK Serverless requires 3)"
  type        = number
  default     = 3
}

variable "ingestion_retention_ms" {
  description = "Retention period in ms for the ingestion topic (default: 7 days)"
  type        = number
  default     = 604800000
}

variable "results_retention_ms" {
  description = "Retention period in ms for the results topic (default: 3 days)"
  type        = number
  default     = 259200000
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 14
}
