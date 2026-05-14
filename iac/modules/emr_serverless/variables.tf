variable "name_prefix" {
  description = "Prefix used to name EMR Serverless resources"
  type        = string
}

variable "release_label" {
  description = "EMR release label for Spark application"
  type        = string
  default     = "emr-6.15.0"
}

variable "application_type" {
  description = "EMR Serverless application type"
  type        = string
  default     = "SPARK"
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by EMR Serverless"
  type        = list(string)
}

variable "emr_security_group_id" {
  description = "Security group ID for EMR Serverless"
  type        = string
}

variable "execution_role_arn" {
  description = "IAM execution role ARN used by job runs"
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch log retention for EMR application logs"
  type        = number
  default     = 14
}

variable "log_bucket_name" {
  description = "S3 bucket name for EMR logs"
  type        = string
}

variable "log_prefix" {
  description = "S3 prefix for EMR logs"
  type        = string
  default     = "emr-serverless/logs"
}

variable "enable_initial_capacity" {
  description = "Whether to pre-warm EMR Serverless with initial capacity. Disable in dev to stay within vCPU quotas."
  type        = bool
  default     = false
}

variable "auto_start_enabled" {
  description = "Whether to auto-start EMR application on job submission"
  type        = bool
  default     = true
}

variable "auto_stop_enabled" {
  description = "Whether to auto-stop EMR application when idle"
  type        = bool
  default     = true
}

variable "idle_timeout_minutes" {
  description = "Idle timeout in minutes before app auto-stop"
  type        = number
  default     = 15
}

variable "initial_driver_worker_count" {
  description = "Initial driver worker count"
  type        = number
  default     = 1
}

variable "initial_driver_cpu" {
  description = "Initial driver CPU"
  type        = string
  default     = "2 vCPU"
}

variable "initial_driver_memory" {
  description = "Initial driver memory"
  type        = string
  default     = "4 GB"
}

variable "initial_executor_worker_count" {
  description = "Initial executor worker count"
  type        = number
  default     = 20
}

variable "initial_executor_cpu" {
  description = "Initial executor CPU"
  type        = string
  default     = "2 vCPU"
}

variable "initial_executor_memory" {
  description = "Initial executor memory"
  type        = string
  default     = "4 GB"
}

variable "maximum_cpu" {
  description = "Maximum aggregate CPU capacity"
  type        = string
  default     = "1000 vCPU"
}

variable "maximum_memory" {
  description = "Maximum aggregate memory capacity"
  type        = string
  default     = "8000 GB"
}

variable "maximum_disk" {
  description = "Maximum aggregate ephemeral disk capacity"
  type        = string
  default     = "20000 GB"
}
