output "vpc_id" {
  description = "Development VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Development public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Development private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "lambda_private_sg_id" {
  description = "Development Lambda private security group ID"
  value       = module.security_groups.lambda_private_sg_id
}

output "emr_sg_id" {
  description = "Development EMR security group ID"
  value       = module.security_groups.emr_sg_id
}

output "msk_connect_sg_id" {
  description = "Development MSK Connect security group ID"
  value       = module.security_groups.msk_connect_sg_id
}

output "msk_sg_id" {
  description = "Development MSK security group ID"
  value       = module.security_groups.msk_sg_id
}

output "sagemaker_endpoint_sg_id" {
  description = "Development SageMaker endpoint security group ID"
  value       = module.security_groups.sagemaker_endpoint_sg_id
}

output "s3_gateway_endpoint_id" {
  description = "Development S3 gateway endpoint ID"
  value       = module.vpc_endpoints.s3_gateway_endpoint_id
}

output "dynamodb_gateway_endpoint_id" {
  description = "Development DynamoDB gateway endpoint ID"
  value       = module.vpc_endpoints.dynamodb_gateway_endpoint_id
}

output "sqs_interface_endpoint_id" {
  description = "Development SQS interface endpoint ID"
  value       = module.vpc_endpoints.sqs_interface_endpoint_id
}

output "sagemaker_runtime_interface_endpoint_id" {
  description = "Development SageMaker runtime interface endpoint ID"
  value       = module.vpc_endpoints.sagemaker_runtime_interface_endpoint_id
}

output "results_dispatcher_role_arn" {
  description = "Development results dispatcher role ARN"
  value       = module.iam.results_dispatcher_role_arn
}

output "emr_serverless_execution_role_arn" {
  description = "Development EMR Serverless execution role ARN"
  value       = module.iam.emr_serverless_execution_role_arn
}

output "sagemaker_execution_role_arn" {
  description = "Development SageMaker execution role ARN"
  value       = module.iam.sagemaker_execution_role_arn
}

output "msk_connect_execution_role_arn" {
  description = "Development MSK Connect execution role ARN"
  value       = module.iam.msk_connect_execution_role_arn
}

output "jobs_table_name" {
  description = "Development DynamoDB jobs table name"
  value       = module.data_layer.jobs_table_name
}

output "jobs_table_arn" {
  description = "Development DynamoDB jobs table ARN"
  value       = module.data_layer.jobs_table_arn
}

output "ingestion_queue_name" {
  description = "Development SQS ingestion queue name"
  value       = module.data_layer.ingestion_queue_name
}

output "auth_api_role_arn" {
  description = "Development auth-api Lambda role ARN"
  value       = module.iam.auth_api_role_arn
}

output "classification_api_role_arn" {
  description = "Development classification-api Lambda role ARN"
  value       = module.iam.classification_api_role_arn
}

output "upload_api_role_arn" {
  description = "Development upload-api Lambda role ARN"
  value       = module.iam.upload_api_role_arn
}

output "ingestion_api_role_arn" {
  description = "Development ingestion-api Lambda role ARN"
  value       = module.iam.ingestion_api_role_arn
}

output "public_api_endpoint" {
  description = "Raw API Gateway invoke URL (public). Direct access is blocked by WAF (X-Origin-Verify); traffic must flow through CloudFront at var.domain_name."
  value       = module.api_gateway.public_api_endpoint
}

output "auth_api_function_name" {
  description = "Development auth API Lambda function name"
  value       = module.api_gateway.auth_api_function_name
}

output "classification_api_function_name" {
  description = "Development classification API Lambda function name"
  value       = module.api_gateway.classification_api_function_name
}

output "ingestion_queue_arn" {
  description = "Development SQS ingestion queue ARN"
  value       = module.data_layer.ingestion_queue_arn
}

output "ingestion_dlq_name" {
  description = "Development SQS ingestion DLQ name"
  value       = module.data_layer.ingestion_dlq_name
}

output "ingestion_dlq_arn" {
  description = "Development SQS ingestion DLQ ARN"
  value       = module.data_layer.ingestion_dlq_arn
}

output "data_layer_msk_cluster_name" {
  description = "Development MSK Serverless cluster name"
  value       = module.data_layer.msk_cluster_name
}

output "data_layer_msk_cluster_arn" {
  description = "Development MSK Serverless cluster ARN"
  value       = module.data_layer.msk_cluster_arn
}

output "data_layer_msk_bootstrap_brokers_sasl_iam" {
  description = "Development MSK IAM bootstrap brokers"
  value       = module.data_layer.msk_bootstrap_brokers_sasl_iam
}

output "msk_connect_connector_name" {
  description = "Development MSK Connect connector name"
  value       = module.data_layer.msk_connect_connector_name
}

output "msk_connect_connector_arn" {
  description = "Development MSK Connect connector ARN"
  value       = module.data_layer.msk_connect_connector_arn
}

output "emr_serverless_application_id" {
  description = "Development EMR Serverless application ID"
  value       = module.emr_serverless.application_id
}

output "emr_serverless_application_arn" {
  description = "Development EMR Serverless application ARN"
  value       = module.emr_serverless.application_arn
}

output "emr_serverless_log_group_name" {
  description = "Development EMR Serverless CloudWatch log group"
  value       = module.emr_serverless.cloudwatch_log_group_name
}

output "emr_serverless_logs_s3_uri" {
  description = "Development EMR Serverless S3 logs URI"
  value       = module.emr_serverless.s3_log_uri
}

output "s3_images_bucket_name" {
  description = "Galaxy images S3 bucket"
  value       = module.s3.images_bucket_name
}

output "s3_checkpoints_bucket_name" {
  description = "Spark checkpoints and EMR artifacts S3 bucket"
  value       = module.s3.checkpoints_bucket_name
}

output "s3_models_bucket_name" {
  description = "ML model artifacts S3 bucket"
  value       = module.s3.models_bucket_name
}

output "s3_spa_bucket_name" {
  description = "S3 bucket where the SPA static assets are deployed"
  value       = module.s3.spa_bucket_name
}

output "sagemaker_endpoint_name" {
  description = "SageMaker galaxy classifier endpoint name (use as SAGEMAKER_ENDPOINT_NAME in submit script)"
  value       = module.sagemaker.endpoint_name
}

output "sagemaker_endpoint_arn" {
  description = "SageMaker galaxy classifier endpoint ARN"
  value       = module.sagemaker.endpoint_arn
}

output "private_api_endpoint" {
  description = "Raw API Gateway invoke URL (private: upload + ingestion). Direct access is blocked by WAF (X-Origin-Verify); traffic must flow through CloudFront."
  value       = module.api_gateway_private.private_api_endpoint
}

output "upload_api_function_name" {
  description = "Lambda function name for the upload (presigned URL) API"
  value       = module.api_gateway_private.upload_api_function_name
}

output "ingestion_api_function_name" {
  description = "Lambda function name for the ingestion (quota + SQS) API"
  value       = module.api_gateway_private.ingestion_api_function_name
}

output "appsync_graphql_url" {
  description = "AppSync GraphQL endpoint — custom domain (https://api.galaxymorph.com/graphql)"
  value       = module.appsync_domain.graphql_url
}

output "appsync_realtime_url" {
  description = "AppSync real-time WebSocket endpoint — custom domain (wss://api.galaxymorph.com/graphql/realtime)"
  value       = module.appsync_domain.realtime_url
}

output "appsync_api_id" {
  description = "AppSync GraphQL API ID"
  value       = module.appsync.api_id
}

output "results_dispatcher_function_name" {
  description = "Results dispatcher Lambda function name"
  value       = module.results_dispatcher.results_dispatcher_function_name
}

output "cloudfront_app_url" {
  description = "Primary application URL served by CloudFront (https://galaxymorph.com)"
  value       = "https://${var.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — required for cache invalidations in CI/CD (aws cloudfront create-invalidation)"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_distribution_domain_name" {
  description = "CloudFront-assigned domain (e.g. d1234abcd.cloudfront.net) — useful before DNS propagates"
  value       = module.cloudfront.distribution_domain_name
}
