output "lambda_execution_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_execution.arn
}

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

output "lambda_api_role_arn" {
  description = "Lambda API role ARN (auth + classification public endpoints)"
  value       = aws_iam_role.lambda_api.arn
}

output "post_confirmation_role_arn" {
  description = "IAM role ARN for the Cognito Post Confirmation Lambda trigger"
  value       = aws_iam_role.post_confirmation.arn
}

output "lambda_private_api_role_arn" {
  description = "IAM role ARN for the private API Lambdas (upload + ingestion)"
  value       = aws_iam_role.lambda_private_api.arn
}
