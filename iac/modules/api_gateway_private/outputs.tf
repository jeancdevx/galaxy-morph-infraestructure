output "private_api_endpoint" {
  description = "Invoke URL for the private REST API stage"
  value       = aws_api_gateway_stage.private.invoke_url
}

output "upload_api_function_name" {
  description = "Lambda function name for the upload API"
  value       = aws_lambda_function.upload_api.function_name
}

output "ingestion_api_function_name" {
  description = "Lambda function name for the ingestion API"
  value       = aws_lambda_function.ingestion_api.function_name
}
