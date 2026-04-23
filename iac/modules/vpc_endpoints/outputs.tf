output "s3_gateway_endpoint_id" {
  description = "S3 gateway endpoint ID"
  value       = var.enable_s3_gateway_endpoint ? aws_vpc_endpoint.s3_gateway[0].id : null
}

output "dynamodb_gateway_endpoint_id" {
  description = "DynamoDB gateway endpoint ID"
  value       = var.enable_dynamodb_gateway_endpoint ? aws_vpc_endpoint.dynamodb_gateway[0].id : null
}

output "sqs_interface_endpoint_id" {
  description = "SQS interface endpoint ID"
  value       = var.enable_sqs_interface_endpoint ? aws_vpc_endpoint.sqs_interface[0].id : null
}

output "sagemaker_runtime_interface_endpoint_id" {
  description = "SageMaker runtime interface endpoint ID"
  value       = var.enable_sagemaker_runtime_interface_endpoint ? aws_vpc_endpoint.sagemaker_runtime_interface[0].id : null
}
