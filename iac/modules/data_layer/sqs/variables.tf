variable "name_prefix" {
  description = "Prefix used to name SQS resources"
  type        = string
}

variable "ingestion_queue_name" {
  description = "SQS ingestion queue name"
  type        = string
}

variable "ingestion_dlq_name" {
  description = "SQS dead-letter queue name"
  type        = string
}

variable "ingestion_queue_visibility_timeout_seconds" {
  description = "Visibility timeout in seconds for ingestion queue"
  type        = number
}

variable "ingestion_queue_message_retention_seconds" {
  description = "Message retention in seconds for ingestion queue"
  type        = number
}

variable "ingestion_queue_max_receive_count" {
  description = "Max receive count before moving to DLQ"
  type        = number
}
