output "invocation_result" {
  description = "JSON result from the Kafka setup Lambda invocation"
  value       = aws_lambda_invocation.kafka_setup.result
}
