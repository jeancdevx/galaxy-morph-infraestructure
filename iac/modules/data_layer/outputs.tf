output "jobs_table_name" {
  description = "DynamoDB jobs table name"
  value       = module.dynamodb.jobs_table_name
}

output "jobs_table_arn" {
  description = "DynamoDB jobs table ARN"
  value       = module.dynamodb.jobs_table_arn
}

output "ingestion_queue_name" {
  description = "SQS ingestion queue name"
  value       = module.sqs.ingestion_queue_name
}

output "ingestion_queue_arn" {
  description = "SQS ingestion queue ARN"
  value       = module.sqs.ingestion_queue_arn
}

output "ingestion_queue_url" {
  description = "SQS ingestion queue URL"
  value       = module.sqs.ingestion_queue_url
}

output "ingestion_dlq_name" {
  description = "SQS ingestion dead-letter queue name"
  value       = module.sqs.ingestion_dlq_name
}

output "ingestion_dlq_arn" {
  description = "SQS ingestion dead-letter queue ARN"
  value       = module.sqs.ingestion_dlq_arn
}

output "msk_cluster_name" {
  description = "MSK Serverless cluster name"
  value       = module.msk.msk_cluster_name
}

output "msk_cluster_arn" {
  description = "MSK Serverless cluster ARN"
  value       = module.msk.msk_cluster_arn
}

locals {
  _msk_arn_base = regex("^(arn:aws:kafka:[^:]+:[^:]+):cluster/([^/]+)/.*$", module.msk.msk_cluster_arn)
}

output "msk_topic_arn_prefix" {
  description = "ARN prefix for MSK topics used in IAM policies"
  value       = "${local._msk_arn_base[0]}:topic/${local._msk_arn_base[1]}/*"
}

output "msk_group_arn_prefix" {
  description = "ARN prefix for MSK consumer groups used in IAM policies"
  value       = "${local._msk_arn_base[0]}:group/${local._msk_arn_base[1]}/*"
}

output "msk_bootstrap_brokers_sasl_iam" {
  description = "MSK Serverless IAM bootstrap brokers"
  value       = module.msk.msk_bootstrap_brokers_sasl_iam
}

output "msk_connect_connector_name" {
  description = "MSK Connect connector name"
  value       = module.msk_connect.connector_name
}

output "msk_connect_connector_arn" {
  description = "MSK Connect connector ARN"
  value       = module.msk_connect.connector_arn
}
