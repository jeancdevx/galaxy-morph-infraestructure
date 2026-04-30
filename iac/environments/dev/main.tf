data "aws_caller_identity" "current" {}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix          = "${var.project_name}-${var.environment}"
  region_prefix        = var.aws_region
  vpc_cidr_block       = var.vpc_cidr_block
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
}

module "security_groups" {
  source = "../../modules/security_groups"

  name_prefix          = "${var.project_name}-${var.environment}"
  vpc_id               = module.vpc.vpc_id
  msk_port             = var.msk_port
  sagemaker_https_port = var.sagemaker_https_port
}

module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  name_prefix             = "${var.project_name}-${var.environment}"
  aws_region              = var.aws_region
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  private_route_table_ids = module.vpc.private_route_table_ids
  endpoint_security_group_ids = [
    module.security_groups.vpc_endpoints_sg_id,
  ]

  enable_s3_gateway_endpoint                  = var.enable_s3_gateway_endpoint
  enable_dynamodb_gateway_endpoint            = var.enable_dynamodb_gateway_endpoint
  enable_sqs_interface_endpoint               = var.enable_sqs_interface_endpoint
  enable_sagemaker_runtime_interface_endpoint = var.enable_sagemaker_runtime_interface_endpoint
  enable_private_dns                          = var.enable_private_dns
}

module "data_layer" {
  source = "../../modules/data_layer"

  name_prefix           = "${var.project_name}-${var.environment}"
  aws_region            = var.aws_region
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  msk_security_group_id = module.security_groups.msk_sg_id

  # DynamoDB
  jobs_table_name               = var.jobs_table_name
  jobs_table_hash_key           = var.jobs_table_hash_key
  jobs_table_range_key          = var.jobs_table_range_key
  enable_point_in_time_recovery = var.enable_jobs_table_pitr
  enable_ttl                    = var.enable_jobs_table_ttl
  enable_gsi_client_status      = var.enable_jobs_table_gsi

  # SQS
  ingestion_queue_name                       = var.ingestion_queue_name
  ingestion_dlq_name                         = var.ingestion_dlq_name
  ingestion_queue_visibility_timeout_seconds = var.ingestion_queue_visibility_timeout_seconds
  ingestion_queue_message_retention_seconds  = var.ingestion_queue_message_retention_seconds
  ingestion_queue_max_receive_count          = var.ingestion_queue_max_receive_count

  # MSK
  msk_cluster_name = var.msk_cluster_name

  # MSK Connect
  enable_msk_connect_connector   = var.enable_msk_connect_connector
  msk_connect_security_group_id  = module.security_groups.msk_connect_sg_id
  msk_connect_execution_role_arn = module.iam.msk_connect_execution_role_arn

  raw_bucket_name = var.raw_bucket_name
  raw_bucket_arn  = "arn:aws:s3:::${var.raw_bucket_name}"

  kafka_ui_execution_role_arn = module.iam.kafka_ui_execution_role_arn
  kafka_ui_task_role_arn      = module.iam.kafka_ui_task_role_arn
  public_subnet_ids           = module.vpc.public_subnet_ids

  ingestion_topic_name             = var.ingestion_topic_name
  msk_connect_kafkaconnect_version = var.msk_connect_kafkaconnect_version
  msk_connect_mcu_count            = var.msk_connect_mcu_count
  msk_connect_min_worker_count     = var.msk_connect_min_worker_count
  msk_connect_max_worker_count     = var.msk_connect_max_worker_count
  msk_connect_tasks_max            = var.msk_connect_tasks_max
  msk_connect_log_retention_days   = var.msk_connect_log_retention_days
}

module "iam" {
  source = "../../modules/iam"

  name_prefix    = "${var.project_name}-${var.environment}"
  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id

  jobs_table_name         = module.data_layer.jobs_table_name
  images_bucket_name      = var.images_bucket_name
  checkpoints_bucket_name = var.checkpoints_bucket_name
  models_bucket_name      = var.models_bucket_name
  raw_bucket_name         = var.raw_bucket_name

  appsync_api_arn     = var.appsync_api_arn
  msk_cluster_arn     = module.data_layer.msk_cluster_arn
  ingestion_queue_arn = module.data_layer.ingestion_queue_arn
}

module "cognito" {
  source = "../../modules/cognito"

  name_prefix       = "${var.project_name}-${var.environment}"
  app_email_subject = var.project_name
}
