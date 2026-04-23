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
