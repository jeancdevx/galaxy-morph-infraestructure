output "lambda_private_sg_id" {
  description = "Private Lambda security group ID"
  value       = aws_security_group.lambda_private.id
}

output "emr_sg_id" {
  description = "EMR Serverless security group ID"
  value       = aws_security_group.emr.id
}

output "msk_connect_sg_id" {
  description = "MSK Connect security group ID"
  value       = aws_security_group.msk_connect.id
}

output "msk_sg_id" {
  description = "MSK Serverless security group ID"
  value       = aws_security_group.msk.id
}

output "sagemaker_endpoint_sg_id" {
  description = "SageMaker endpoint security group ID"
  value       = aws_security_group.sagemaker_endpoint.id
}
