output "connector_name" {
  description = "MSK Connect connector name"
  value       = var.enable_connector ? aws_mskconnect_connector.sqs_source[0].name : null
}

output "connector_arn" {
  description = "MSK Connect connector ARN"
  value       = var.enable_connector ? aws_mskconnect_connector.sqs_source[0].arn : null
}

output "connector_log_group_name" {
  description = "CloudWatch log group for the connector"
  value       = var.enable_connector ? aws_cloudwatch_log_group.connector[0].name : null
}
