data "aws_caller_identity" "current" {}

module "s3" {
  source = "../../modules/s3"

  images_bucket_name      = var.images_bucket_name
  checkpoints_bucket_name = var.checkpoints_bucket_name
  models_bucket_name      = var.models_bucket_name
}

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
  jobs_table_name                   = var.jobs_table_name
  jobs_table_hash_key               = var.jobs_table_hash_key
  jobs_table_range_key              = var.jobs_table_range_key
  enable_point_in_time_recovery     = var.enable_jobs_table_pitr
  enable_ttl                        = var.enable_jobs_table_ttl
  enable_gsi_client_status          = var.enable_jobs_table_gsi
  enable_gsi_entity_type_created_at = var.enable_jobs_table_gsi_community

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

  appsync_api_arn      = var.appsync_api_arn
  msk_cluster_arn      = module.data_layer.msk_cluster_arn
  msk_topic_arn_prefix = module.data_layer.msk_topic_arn_prefix
  msk_group_arn_prefix = module.data_layer.msk_group_arn_prefix
  ingestion_queue_arn  = module.data_layer.ingestion_queue_arn

  cognito_user_pool_id = module.cognito.user_pool_id
}

module "emr_serverless" {
  source = "../../modules/emr_serverless"

  name_prefix           = "${var.project_name}-${var.environment}"
  private_subnet_ids    = module.vpc.private_subnet_ids
  emr_security_group_id = module.security_groups.emr_sg_id
  execution_role_arn    = module.iam.emr_serverless_execution_role_arn

  log_bucket_name = var.checkpoints_bucket_name
  log_prefix      = var.emr_serverless_log_prefix

  release_label                 = var.emr_release_label
  enable_initial_capacity       = var.emr_enable_initial_capacity
  idle_timeout_minutes          = var.emr_idle_timeout_minutes
  log_retention_days            = var.emr_log_retention_days
  initial_driver_worker_count   = var.emr_initial_driver_worker_count
  initial_driver_cpu            = var.emr_initial_driver_cpu
  initial_driver_memory         = var.emr_initial_driver_memory
  initial_executor_worker_count = var.emr_initial_executor_worker_count
  initial_executor_cpu          = var.emr_initial_executor_cpu
  initial_executor_memory       = var.emr_initial_executor_memory
  maximum_cpu                   = var.emr_maximum_cpu
  maximum_memory                = var.emr_maximum_memory
  maximum_disk                  = var.emr_maximum_disk
}

module "sagemaker" {
  source = "../../modules/sagemaker"

  name_prefix            = "${var.project_name}-${var.environment}"
  execution_role_arn     = module.iam.sagemaker_execution_role_arn
  model_artifact_s3_uri  = var.sagemaker_model_artifact_s3_uri
  image_uri              = var.sagemaker_image_uri
  instance_type          = var.sagemaker_instance_type
  initial_instance_count = var.sagemaker_initial_instance_count

  enable_vpc_config  = var.sagemaker_enable_vpc_config
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.sagemaker_endpoint_sg_id]

  enable_sagemaker_endpoint      = var.sagemaker_enable_endpoint
  enable_autoscaling             = var.sagemaker_enable_autoscaling
  autoscaling_min_capacity       = var.sagemaker_autoscaling_min_capacity
  autoscaling_max_capacity       = var.sagemaker_autoscaling_max_capacity
  autoscaling_target_invocations = var.sagemaker_autoscaling_target_invocations
}

module "cognito" {
  source = "../../modules/cognito"

  name_prefix                = "${var.project_name}-${var.environment}"
  app_email_subject          = var.project_name
  aws_region                 = var.aws_region
  aws_account_id             = data.aws_caller_identity.current.account_id
  post_confirmation_role_arn = module.iam.post_confirmation_role_arn
  log_retention_days         = var.api_log_retention_days
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  name_prefix           = "${var.project_name}-${var.environment}"
  aws_region            = var.aws_region
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_client_id     = module.cognito.frontend_client_id
  lambda_api_role_arn   = module.iam.lambda_api_role_arn
  jobs_table_name       = module.data_layer.jobs_table_name
  stage_name            = var.api_stage_name

  lambda_timeout     = var.api_lambda_timeout
  lambda_memory_size = var.api_lambda_memory_size
  log_retention_days = var.api_log_retention_days
}
