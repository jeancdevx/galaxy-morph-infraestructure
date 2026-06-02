output "private_api_endpoint" {
  description = "Invoke URL for the private REST API stage"
  value       = aws_api_gateway_stage.private.invoke_url
}

output "private_stage_arn" {
  description = "ARN of the private API Gateway stage — used for WAF WebACL association"
  value       = aws_api_gateway_stage.private.arn
}

output "upload_api_function_name" {
  description = "Lambda function name for the upload API"
  value       = aws_lambda_function.upload_api.function_name
}

output "ingestion_api_function_name" {
  description = "Lambda function name for the ingestion API"
  value       = aws_lambda_function.ingestion_api.function_name
}
