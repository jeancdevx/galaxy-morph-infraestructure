output "vpc_id" {
  description = "Development VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Development public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Development private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "lambda_private_sg_id" {
  description = "Development Lambda private security group ID"
  value       = module.security_groups.lambda_private_sg_id
}

output "emr_sg_id" {
  description = "Development EMR security group ID"
  value       = module.security_groups.emr_sg_id
}

output "msk_connect_sg_id" {
  description = "Development MSK Connect security group ID"
  value       = module.security_groups.msk_connect_sg_id
}

output "msk_sg_id" {
  description = "Development MSK security group ID"
  value       = module.security_groups.msk_sg_id
}

output "sagemaker_endpoint_sg_id" {
  description = "Development SageMaker endpoint security group ID"
  value       = module.security_groups.sagemaker_endpoint_sg_id
}

output "s3_gateway_endpoint_id" {
  description = "Development S3 gateway endpoint ID"
  value       = module.vpc_endpoints.s3_gateway_endpoint_id
}

output "dynamodb_gateway_endpoint_id" {
  description = "Development DynamoDB gateway endpoint ID"
  value       = module.vpc_endpoints.dynamodb_gateway_endpoint_id
}

output "sqs_interface_endpoint_id" {
  description = "Development SQS interface endpoint ID"
  value       = module.vpc_endpoints.sqs_interface_endpoint_id
}

output "sagemaker_runtime_interface_endpoint_id" {
  description = "Development SageMaker runtime interface endpoint ID"
  value       = module.vpc_endpoints.sagemaker_runtime_interface_endpoint_id
}

output "lambda_execution_role_arn" {
  description = "Development Lambda execution role ARN"
  value       = module.iam.lambda_execution_role_arn
}

output "results_dispatcher_role_arn" {
  description = "Development results dispatcher role ARN"
  value       = module.iam.results_dispatcher_role_arn
}

output "emr_serverless_execution_role_arn" {
  description = "Development EMR Serverless execution role ARN"
  value       = module.iam.emr_serverless_execution_role_arn
}

output "sagemaker_execution_role_arn" {
  description = "Development SageMaker execution role ARN"
  value       = module.iam.sagemaker_execution_role_arn
}

output "msk_connect_execution_role_arn" {
  description = "Development MSK Connect execution role ARN"
  value       = module.iam.msk_connect_execution_role_arn
}
