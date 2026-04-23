output "user_pool_id" {
  description = "ID del Cognito User Pool"
  value       = aws_cognito_user_pool.pool.id
}

output "user_pool_arn" {
  description = "ARN del Cognito User Pool"
  value       = aws_cognito_user_pool.pool.arn
}

output "user_pool_endpoint" {
  description = "Endpoint del Cognito User Pool"
  value       = aws_cognito_user_pool.pool.endpoint
}

output "frontend_client_id" {
  description = "Client ID del User Pool Client para el frontend"
  value       = aws_cognito_user_pool_client.frontend_client.id
}
