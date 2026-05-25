output "results_dispatcher_function_name" {
  description = "Results dispatcher Lambda function name"
  value       = aws_lambda_function.results_dispatcher.function_name
}

output "results_dispatcher_function_arn" {
  description = "Results dispatcher Lambda function ARN"
  value       = aws_lambda_function.results_dispatcher.arn
}

output "msk_event_source_mapping_uuid" {
  description = "UUID of the MSK event source mapping"
  value       = aws_lambda_event_source_mapping.results_topic.uuid
}
