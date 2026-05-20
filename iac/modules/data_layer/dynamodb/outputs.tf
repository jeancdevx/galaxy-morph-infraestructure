output "jobs_table_name" {
  description = "DynamoDB jobs table name"
  value       = aws_dynamodb_table.jobs.name
}

output "jobs_table_arn" {
  description = "DynamoDB jobs table ARN"
  value       = aws_dynamodb_table.jobs.arn
}

output "jobs_table_gsi_name" {
  description = "DynamoDB jobs table GSI name (clientId-status)"
  value       = var.enable_gsi_client_status ? "clientId-status-index" : null
}

output "jobs_table_community_gsi_name" {
  description = "DynamoDB jobs table GSI name for community feed (entityType-createdAt)"
  value       = var.enable_gsi_entity_type_created_at ? "entityType-createdAt-index" : null
}
