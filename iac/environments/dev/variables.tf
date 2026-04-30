variable "aws_region" {
  description = "AWS region where development resources are provisioned"
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
  default     = "dev"
}

variable "vpc_cidr_block" {
  description = "CIDR block for development VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for development subnets"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs for development"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs for development"
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT gateway in development"
  type        = bool
  default     = true
}

variable "msk_port" {
  description = "MSK Serverless IAM/TLS port"
  type        = number
  default     = 9098
}

variable "sagemaker_https_port" {
  description = "SageMaker runtime HTTPS port"
  type        = number
  default     = 443
}

variable "enable_s3_gateway_endpoint" {
  description = "Whether to create S3 gateway endpoint in development"
  type        = bool
  default     = true
}

variable "enable_dynamodb_gateway_endpoint" {
  description = "Whether to create DynamoDB gateway endpoint in development"
  type        = bool
  default     = true
}

variable "enable_sqs_interface_endpoint" {
  description = "Whether to create SQS interface endpoint in development"
  type        = bool
  default     = true
}

variable "enable_sagemaker_runtime_interface_endpoint" {
  description = "Whether to create SageMaker runtime interface endpoint in development"
  type        = bool
  default     = true
}

variable "enable_private_dns" {
  description = "Whether to enable private DNS in interface endpoints"
  type        = bool
  default     = true
}

variable "jobs_table_name" {
  description = "DynamoDB jobs table name"
  type        = string
  default     = "galaxy-morph-jobs"
}

variable "jobs_table_hash_key" {
  description = "DynamoDB jobs table partition key"
  type        = string
  default     = "pk"
}

variable "jobs_table_range_key" {
  description = "DynamoDB jobs table sort key"
  type        = string
  default     = "sk"
}

variable "enable_jobs_table_pitr" {
  description = "Whether to enable PITR for jobs table"
  type        = bool
  default     = true
}

variable "enable_jobs_table_ttl" {
  description = "Whether to enable TTL for jobs table"
  type        = bool
  default     = true
}

variable "enable_jobs_table_gsi" {
  description = "Whether to enable GSI for jobs table"
  type        = bool
  default     = true
}

variable "ingestion_queue_name" {
  description = "SQS ingestion queue name"
  type        = string
  default     = "galaxy-morph-ingestion"
}

variable "ingestion_dlq_name" {
  description = "SQS ingestion dead-letter queue name"
  type        = string
  default     = "galaxy-morph-ingestion-dlq"
}

variable "ingestion_queue_visibility_timeout_seconds" {
  description = "Visibility timeout for ingestion queue"
  type        = number
  default     = 120
}

variable "ingestion_queue_message_retention_seconds" {
  description = "Message retention for ingestion queue in seconds"
  type        = number
  default     = 345600
}

variable "ingestion_queue_max_receive_count" {
  description = "Maximum receives before sending message to DLQ"
  type        = number
  default     = 5
}

variable "msk_cluster_name" {
  description = "Optional custom name for MSK Serverless cluster"
  type        = string
  default     = null
  nullable    = true
}

variable "enable_msk_connect_connector" {
  description = "Whether to provision the MSK Connect SQS source connector"
  type        = bool
  default     = false
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
  description = "Kafka ingestion topic name"
  type        = string
  default     = "galaxy.ingestion"
}

variable "results_topic_name" {
  description = "Kafka results topic name"
  type        = string
  default     = "galaxy.results"
}

variable "kafka_topic_partitions" {
  description = "Expected Kafka topic partitions count"
  type        = number
  default     = 50
}

variable "kafka_topic_replication_factor" {
  description = "Expected Kafka topic replication factor"
  type        = number
  default     = 3
}

variable "kafka_ingestion_retention_ms" {
  description = "Expected retention for ingestion topic in milliseconds"
  type        = number
  default     = 604800000
}

variable "kafka_results_retention_ms" {
  description = "Expected retention for results topic in milliseconds"
  type        = number
  default     = 259200000
}

variable "msk_connect_kafkaconnect_version" {
  description = "MSK Connect Kafka Connect runtime version"
  type        = string
  default     = "2.7.1"
}

variable "msk_connect_mcu_count" {
  description = "MSK Connect MCU count per worker"
  type        = number
  default     = 1
}

variable "msk_connect_min_worker_count" {
  description = "MSK Connect minimum worker count"
  type        = number
  default     = 2
}

variable "msk_connect_max_worker_count" {
  description = "MSK Connect maximum worker count"
  type        = number
  default     = 10
}

variable "msk_connect_tasks_max" {
  description = "MSK Connect tasks max"
  type        = number
  default     = 16
}

variable "msk_connect_log_retention_days" {
  description = "CloudWatch log retention days for MSK Connect"
  type        = number
  default     = 14
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
  description = "AppSync API ARN used by results dispatcher role"
  type        = string
  default     = "*"
}

variable "msk_cluster_arn" {
  description = "MSK cluster ARN used by streaming components"
  type        = string
  default     = "*"
}
