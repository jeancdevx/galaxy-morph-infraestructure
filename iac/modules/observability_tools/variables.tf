variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the Kafka UI task runs"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the Kafka UI Fargate task"
  type        = list(string)
}

variable "msk_security_group_id" {
  description = "Security group ID attached to MSK — used to allow Kafka UI inbound on port 9098"
  type        = string
}

variable "msk_bootstrap_brokers_sasl_iam" {
  description = "MSK Serverless bootstrap brokers (SASL/IAM) passed to the Kafka UI container"
  type        = string
}

variable "kafka_ui_execution_role_arn" {
  description = "IAM role ARN for Kafka UI ECS task execution"
  type        = string
}

variable "kafka_ui_task_role_arn" {
  description = "IAM role ARN for the Kafka UI ECS task"
  type        = string
}
