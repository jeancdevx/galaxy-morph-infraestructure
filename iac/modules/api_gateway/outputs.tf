output "public_api_id" {
  description = "REST API ID"
  value       = aws_api_gateway_rest_api.public.id
}

output "public_stage_arn" {
  description = "ARN of the API Gateway stage — used for WAF WebACL association"
  value       = aws_api_gateway_stage.public.arn
}

output "public_api_endpoint" {
  description = "REST API invoke URL — https://<id>.execute-api.<region>.amazonaws.com/<stage>"
  value       = aws_api_gateway_stage.public.invoke_url
}

output "auth_api_function_name" {
  description = "Auth API Lambda function name"
  value       = aws_lambda_function.auth_api.function_name
}

output "classification_api_function_name" {
  description = "Classification API Lambda function name"
  value       = aws_lambda_function.classification_api.function_name
}
