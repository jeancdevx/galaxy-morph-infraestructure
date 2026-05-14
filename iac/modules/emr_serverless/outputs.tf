output "application_id" {
  description = "EMR Serverless application ID"
  value       = aws_emrserverless_application.streaming.id
}

output "application_arn" {
  description = "EMR Serverless application ARN"
  value       = aws_emrserverless_application.streaming.arn
}

output "application_name" {
  description = "EMR Serverless application name"
  value       = aws_emrserverless_application.streaming.name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for EMR Serverless"
  value       = aws_cloudwatch_log_group.emr_serverless.name
}

output "s3_log_uri" {
  description = "S3 log URI for EMR Serverless monitoring"
  value       = local.s3_log_uri
}

output "execution_role_arn" {
  description = "Execution role ARN to use in job runs"
  value       = var.execution_role_arn
}
