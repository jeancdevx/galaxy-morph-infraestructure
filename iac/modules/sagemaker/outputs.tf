output "endpoint_name" {
  description = "SageMaker endpoint name — use as SAGEMAKER_ENDPOINT_NAME in the EMR submit script"
  value       = length(aws_sagemaker_endpoint.galaxy_classifier) > 0 ? aws_sagemaker_endpoint.galaxy_classifier[0].name : null
}

output "endpoint_arn" {
  description = "SageMaker endpoint ARN"
  value       = length(aws_sagemaker_endpoint.galaxy_classifier) > 0 ? aws_sagemaker_endpoint.galaxy_classifier[0].arn : null
}
