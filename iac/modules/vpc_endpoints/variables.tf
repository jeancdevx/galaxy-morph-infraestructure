variable "name_prefix" {
  description = "Prefix used to name VPC endpoint resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region used to build endpoint service names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where endpoints will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where interface endpoints will be attached"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "Private route table IDs for gateway endpoints"
  type        = list(string)
}

variable "endpoint_security_group_ids" {
  description = "Security group IDs attached to interface endpoints"
  type        = list(string)
}

variable "enable_s3_gateway_endpoint" {
  description = "Whether to create the S3 gateway endpoint"
  type        = bool
  default     = true
}

variable "enable_dynamodb_gateway_endpoint" {
  description = "Whether to create the DynamoDB gateway endpoint"
  type        = bool
  default     = true
}

variable "enable_sqs_interface_endpoint" {
  description = "Whether to create the SQS interface endpoint"
  type        = bool
  default     = true
}

variable "enable_sagemaker_runtime_interface_endpoint" {
  description = "Whether to create the SageMaker Runtime interface endpoint"
  type        = bool
  default     = true
}

variable "enable_private_dns" {
  description = "Whether to enable private DNS for interface endpoints"
  type        = bool
  default     = true
}
