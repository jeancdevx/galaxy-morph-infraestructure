output "results_dispatcher_role_arn" {
  description = "Results dispatcher Lambda role ARN"
  value       = aws_iam_role.results_dispatcher.arn
}

output "emr_serverless_execution_role_arn" {
  description = "EMR Serverless execution role ARN"
  value       = aws_iam_role.emr_serverless_execution.arn
}

output "sagemaker_execution_role_arn" {
  description = "SageMaker execution role ARN"
  value       = aws_iam_role.sagemaker_execution.arn
}

output "msk_connect_execution_role_arn" {
  description = "MSK Connect execution role ARN"
  value       = aws_iam_role.msk_connect_execution.arn
}

output "kafka_ui_task_role_arn" {
  description = "ARN of the IAM role used by Kafka UI ECS Task"
  value       = aws_iam_role.kafka_ui_task.arn
}

output "kafka_ui_execution_role_arn" {
  description = "ARN of the IAM role used by Kafka UI ECS Execution"
  value       = aws_iam_role.kafka_ui_execution.arn
}

output "auth_api_role_arn" {
  description = "IAM role ARN for the auth-api Lambda (Cognito authentication)"
  value       = aws_iam_role.auth_api.arn
}

output "classification_api_role_arn" {
  description = "IAM role ARN for the classification-api Lambda (DynamoDB query)"
  value       = aws_iam_role.classification_api.arn
}

output "post_confirmation_role_arn" {
  description = "IAM role ARN for the Cognito Post Confirmation Lambda trigger"
  value       = aws_iam_role.post_confirmation.arn
}

output "upload_api_role_arn" {
  description = "IAM role ARN for the upload-api Lambda (S3 presigned URL generation)"
  value       = aws_iam_role.upload_api.arn
}

output "ingestion_api_role_arn" {
  description = "IAM role ARN for the ingestion-api Lambda (DynamoDB write + SQS enqueue)"
  value       = aws_iam_role.ingestion_api.arn
}
