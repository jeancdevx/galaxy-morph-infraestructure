output "endpoint_name" {
  description = "SageMaker endpoint name — use as SAGEMAKER_ENDPOINT_NAME in the EMR submit script"
  value       = aws_sagemaker_endpoint.galaxy_classifier.name
}

output "endpoint_arn" {
  description = "SageMaker endpoint ARN"
  value       = aws_sagemaker_endpoint.galaxy_classifier.arn
}
