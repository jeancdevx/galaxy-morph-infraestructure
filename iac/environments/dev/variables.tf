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
