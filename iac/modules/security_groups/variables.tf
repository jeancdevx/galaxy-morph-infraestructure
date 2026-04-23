variable "name_prefix" {
  description = "Prefix used to name security groups"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
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
