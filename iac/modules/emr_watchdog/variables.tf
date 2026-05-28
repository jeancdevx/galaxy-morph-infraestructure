variable "name_prefix" {
  description = "Prefix used for all resource names"
  type        = string
}

variable "execution_role_arn" {
  description = "IAM role ARN shared by both emr_job_launcher and emr_job_watchdog Lambdas"
  type        = string
}

variable "emr_application_id" {
  description = "EMR Serverless application ID for the streaming classification app"
  type        = string
}

variable "emr_execution_role_arn" {
  description = "IAM role ARN that EMR Serverless assumes when running the Spark job"
  type        = string
}

variable "checkpoints_bucket_name" {
  description = "S3 bucket for Spark checkpoints, EMR logs, and job artifacts"
  type        = string
}

variable "artifact_s3_prefix" {
  description = "S3 key prefix where the EMR job artifact (main_streaming.py + deps.zip) is stored"
  type        = string
  default     = "emr/jobs/streaming_classification/latest"
}

variable "msk_bootstrap_servers" {
  description = "MSK Serverless bootstrap broker string (SASL/IAM, port 9098)"
  type        = string
}

variable "sagemaker_endpoint_name" {
  description = "SageMaker endpoint name used as Spark config and EventBridge filter"
  type        = string
  default     = ""
}

variable "images_bucket_name" {
  description = "S3 bucket containing galaxy images for classification"
  type        = string
}

variable "inference_mode" {
  description = "Inference mode passed to the Spark job: 'sagemaker' or 'stub'"
  type        = string
  default     = "sagemaker"
}

variable "kafka_ingestion_topic" {
  description = "Kafka topic the Spark job reads from"
  type        = string
  default     = "galaxy.ingestion"
}

variable "kafka_results_topic" {
  description = "Kafka topic the Spark job writes results to"
  type        = string
  default     = "galaxy.results"
}

variable "kafka_group_id" {
  description = "Kafka consumer group ID for the streaming job"
  type        = string
  default     = "galaxy-morph-emr-streaming"
}

variable "trigger_interval_seconds" {
  description = "Spark Structured Streaming micro-batch trigger interval in seconds"
  type        = number
  default     = 5
}

variable "inference_retries" {
  description = "Number of SageMaker inference retries per image"
  type        = number
  default     = 3
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 14
}
