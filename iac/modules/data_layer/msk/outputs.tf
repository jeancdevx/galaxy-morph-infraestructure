output "msk_cluster_name" {
  description = "MSK Serverless cluster name"
  value       = aws_msk_serverless_cluster.this.cluster_name
}

output "msk_cluster_arn" {
  description = "MSK Serverless cluster ARN"
  value       = aws_msk_serverless_cluster.this.arn
}

output "msk_bootstrap_brokers_sasl_iam" {
  description = "MSK Serverless IAM bootstrap brokers"
  value       = aws_msk_serverless_cluster.this.bootstrap_brokers_sasl_iam
}
