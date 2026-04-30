output "ingestion_queue_name" {
  description = "SQS ingestion queue name"
  value       = aws_sqs_queue.ingestion.name
}

output "ingestion_queue_arn" {
  description = "SQS ingestion queue ARN"
  value       = aws_sqs_queue.ingestion.arn
}

output "ingestion_queue_url" {
  description = "SQS ingestion queue URL"
  value       = aws_sqs_queue.ingestion.url
}

output "ingestion_dlq_name" {
  description = "SQS ingestion DLQ name"
  value       = aws_sqs_queue.ingestion_dlq.name
}

output "ingestion_dlq_arn" {
  description = "SQS ingestion DLQ ARN"
  value       = aws_sqs_queue.ingestion_dlq.arn
}
