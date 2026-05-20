variable "enable_sagemaker_endpoint" {
  description = "Whether to create the SageMaker model, endpoint configuration and endpoint. Set false on first apply, true after model.tar.gz is uploaded to S3."
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Name prefix for all SageMaker resources"
  type        = string
}

variable "execution_role_arn" {
  description = "IAM role ARN for SageMaker to access S3 model artifacts and write logs"
  type        = string
}

variable "model_artifact_s3_uri" {
  description = "S3 URI of the model.tar.gz bundle (e.g. s3://bucket/path/model.tar.gz)"
  type        = string
}

variable "image_uri" {
  description = "ECR URI of the SageMaker inference container (AWS PyTorch DLC or custom)"
  type        = string
}

variable "instance_type" {
  description = "SageMaker endpoint instance type"
  type        = string
  default     = "ml.m5.large"
}

variable "initial_instance_count" {
  description = "Initial number of instances behind the endpoint"
  type        = number
  default     = 1
}

# VPC config — disabled by default (public endpoint); enable for prod
variable "enable_vpc_config" {
  description = "Deploy the SageMaker model inside the VPC (required for prod, optional for dev)"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Private subnet IDs for VPC config (used when enable_vpc_config = true)"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for VPC config (used when enable_vpc_config = true)"
  type        = list(string)
  default     = []
}

# Autoscaling — disabled by default; enable for prod or sustained load
variable "enable_autoscaling" {
  description = "Enable Application Auto Scaling on the endpoint variant"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of instances when autoscaling is enabled"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of instances when autoscaling is enabled"
  type        = number
  default     = 2
}

variable "autoscaling_target_invocations" {
  description = "Target invocations per instance per minute for TargetTracking scaling"
  type        = number
  default     = 10
}

# Alarm thresholds
variable "error_alarm_threshold" {
  description = "Number of 5XX errors per evaluation period that triggers the alarm"
  type        = number
  default     = 5
}

variable "latency_alarm_threshold_us" {
  description = "P99 ModelLatency threshold in microseconds (SageMaker reports in µs; default 5s)"
  type        = number
  default     = 5000000
}
