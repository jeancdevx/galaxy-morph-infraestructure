data "aws_caller_identity" "current" {}

data "aws_route53_zone" "main" {
  zone_id = var.route53_zone_id
}

locals {
  name_prefix             = "${var.project_name}-${var.environment}"
  sagemaker_endpoint_name = "${var.project_name}-${var.environment}-galaxy-classifier"
}

# CloudFront origin-verify secret
resource "random_password" "origin_verify_secret" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "origin_verify_secret" {
  name  = "/${local.name_prefix}/cloudfront/origin-verify-secret"
  type  = "SecureString"
  value = random_password.origin_verify_secret.result

  lifecycle {
    ignore_changes = [value]
  }
}

module "s3" {
  source = "../../modules/s3"

  images_bucket_name      = var.images_bucket_name
  checkpoints_bucket_name = var.checkpoints_bucket_name
  models_bucket_name      = var.models_bucket_name
  spa_bucket_name         = var.spa_bucket_name
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix          = local.name_prefix
  region_prefix        = var.aws_region
  vpc_cidr_block       = var.vpc_cidr_block
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
}

module "security_groups" {
  source = "../../modules/security_groups"

  name_prefix          = local.name_prefix
  vpc_id               = module.vpc.vpc_id
  msk_port             = var.msk_port
  sagemaker_https_port = var.sagemaker_https_port
}

module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  name_prefix             = local.name_prefix
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

  name_prefix           = local.name_prefix
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

  name_prefix    = local.name_prefix
  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id

  jobs_table_name         = module.data_layer.jobs_table_name
  images_bucket_name      = var.images_bucket_name
  checkpoints_bucket_name = var.checkpoints_bucket_name
  models_bucket_name      = var.models_bucket_name
  raw_bucket_name         = var.raw_bucket_name

  appsync_api_arn      = module.appsync.api_arn
  msk_cluster_arn      = module.data_layer.msk_cluster_arn
  msk_topic_arn_prefix = module.data_layer.msk_topic_arn_prefix
  msk_group_arn_prefix = module.data_layer.msk_group_arn_prefix
  ingestion_queue_arn  = module.data_layer.ingestion_queue_arn

  cognito_user_pool_id = module.cognito.user_pool_id

  sagemaker_endpoint_arn = var.sagemaker_endpoint_arn
  ecr_repository_arn     = var.ecr_repository_arn

  emr_application_arn = module.emr_serverless.application_arn
}

module "observability_tools" {
  source = "../../modules/observability_tools"

  name_prefix                    = local.name_prefix
  aws_region                     = var.aws_region
  vpc_id                         = module.vpc.vpc_id
  public_subnet_ids              = module.vpc.public_subnet_ids
  msk_security_group_id          = module.security_groups.msk_sg_id
  msk_bootstrap_brokers_sasl_iam = module.data_layer.msk_bootstrap_brokers_sasl_iam
  kafka_ui_execution_role_arn    = module.iam.kafka_ui_execution_role_arn
  kafka_ui_task_role_arn         = module.iam.kafka_ui_task_role_arn

  depends_on = [module.data_layer]
}

module "emr_serverless" {
  source = "../../modules/emr_serverless"

  name_prefix           = local.name_prefix
  private_subnet_ids    = module.vpc.private_subnet_ids
  emr_security_group_id = module.security_groups.emr_sg_id
  execution_role_arn    = module.iam.emr_serverless_execution_role_arn

  log_bucket_name = var.checkpoints_bucket_name
  log_prefix      = var.emr_serverless_log_prefix

  release_label                 = var.emr_release_label
  enable_initial_capacity       = var.emr_enable_initial_capacity
  idle_timeout_minutes          = var.emr_idle_timeout_minutes
  auto_stop_enabled             = var.emr_auto_stop_enabled
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

  name_prefix            = local.name_prefix
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

  name_prefix                = local.name_prefix
  app_email_subject          = var.project_name
  aws_region                 = var.aws_region
  aws_account_id             = data.aws_caller_identity.current.account_id
  post_confirmation_role_arn = module.iam.post_confirmation_role_arn
  log_retention_days         = var.api_log_retention_days
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  name_prefix                 = local.name_prefix
  aws_region                  = var.aws_region
  cognito_user_pool_id        = module.cognito.user_pool_id
  cognito_user_pool_arn       = module.cognito.user_pool_arn
  cognito_client_id           = module.cognito.frontend_client_id
  auth_api_role_arn           = module.iam.auth_api_role_arn
  classification_api_role_arn = module.iam.classification_api_role_arn
  jobs_table_name             = module.data_layer.jobs_table_name
  stage_name                  = var.api_stage_name

  cors_allow_origins = ["https://${var.domain_name}", "http://localhost:3000"]

  lambda_timeout     = var.api_lambda_timeout
  lambda_memory_size = var.api_lambda_memory_size
  log_retention_days = var.api_log_retention_days
}

module "api_gateway_private" {
  source = "../../modules/api_gateway_private"

  name_prefix            = local.name_prefix
  aws_region             = var.aws_region
  cognito_user_pool_id   = module.cognito.user_pool_id
  cognito_user_pool_arn  = module.cognito.user_pool_arn
  upload_api_role_arn    = module.iam.upload_api_role_arn
  ingestion_api_role_arn = module.iam.ingestion_api_role_arn
  images_bucket_name     = var.images_bucket_name
  jobs_table_name        = module.data_layer.jobs_table_name
  ingestion_queue_url    = module.data_layer.ingestion_queue_url
  stage_name             = var.api_stage_name

  lambda_timeout     = var.api_lambda_timeout
  lambda_memory_size = var.api_lambda_memory_size
  log_retention_days = var.api_log_retention_days
  cors_allow_origins = ["https://${var.domain_name}", "http://localhost:3000"]

  depends_on = [module.api_gateway]
}

module "appsync" {
  source = "../../modules/appsync"

  name_prefix          = local.name_prefix
  aws_region           = var.aws_region
  cognito_user_pool_id = module.cognito.user_pool_id
  log_retention_days   = var.api_log_retention_days
}

module "results_dispatcher" {
  source = "../../modules/results_dispatcher"

  name_prefix                 = local.name_prefix
  results_dispatcher_role_arn = module.iam.results_dispatcher_role_arn
  private_subnet_ids          = module.vpc.private_subnet_ids
  lambda_private_sg_id        = module.security_groups.lambda_private_sg_id
  jobs_table_name             = module.data_layer.jobs_table_name
  appsync_graphql_url         = module.appsync.graphql_url
  msk_cluster_arn             = module.data_layer.msk_cluster_arn
  results_topic_name          = var.results_topic_name
  lambda_timeout              = var.dispatcher_lambda_timeout
  lambda_memory_size          = var.dispatcher_lambda_memory_size
  log_retention_days          = var.api_log_retention_days

  depends_on = [module.appsync, module.data_layer]
}

module "kafka_setup" {
  source = "../../modules/kafka_setup"

  name_prefix          = local.name_prefix
  execution_role_arn   = module.iam.kafka_setup_role_arn
  private_subnet_ids   = module.vpc.private_subnet_ids
  lambda_private_sg_id = module.security_groups.lambda_private_sg_id

  kafka_bootstrap_servers  = module.data_layer.msk_bootstrap_brokers_sasl_iam
  ingestion_topic_name     = var.ingestion_topic_name
  results_topic_name       = var.results_topic_name
  topic_partitions         = var.kafka_topic_partitions
  topic_replication_factor = 3 # MSK Serverless always uses 3 AZs
  ingestion_retention_ms   = var.kafka_ingestion_retention_ms
  results_retention_ms     = var.kafka_results_retention_ms
  log_retention_days       = var.api_log_retention_days

  depends_on = [module.data_layer, module.iam]
}

module "emr_watchdog" {
  source = "../../modules/emr_watchdog"

  name_prefix            = local.name_prefix
  execution_role_arn     = module.iam.emr_watchdog_role_arn
  emr_application_id     = module.emr_serverless.application_id
  emr_execution_role_arn = module.iam.emr_serverless_execution_role_arn

  checkpoints_bucket_name = var.checkpoints_bucket_name
  images_bucket_name      = var.images_bucket_name
  msk_bootstrap_servers   = module.data_layer.msk_bootstrap_brokers_sasl_iam

  sagemaker_endpoint_name = local.sagemaker_endpoint_name

  kafka_ingestion_topic = var.ingestion_topic_name
  kafka_results_topic   = var.results_topic_name
  log_retention_days    = var.api_log_retention_days

  depends_on = [module.emr_serverless, module.iam]
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  name_prefix     = local.name_prefix
  domain_name     = var.domain_name
  aliases         = var.cloudfront_aliases
  price_class     = var.cloudfront_price_class
  route53_zone_id = data.aws_route53_zone.main.zone_id

  spa_bucket_id     = module.s3.spa_bucket_name
  spa_bucket_arn    = module.s3.spa_bucket_arn
  images_bucket_id  = module.s3.images_bucket_name
  images_bucket_arn = module.s3.images_bucket_arn

  api_gateway_invoke_url         = module.api_gateway.public_api_endpoint
  private_api_gateway_invoke_url = module.api_gateway_private.private_api_endpoint

  certificate_arn = module.acm.certificate_arn
  waf_web_acl_arn = module.waf_cloudfront.web_acl_arn

  origin_verify_secret = random_password.origin_verify_secret.result

  log_retention_days = var.cloudfront_log_retention_days
}

module "acm" {
  source = "../../modules/acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name_prefix               = local.name_prefix
  domain_name               = var.domain_name
  subject_alternative_names = var.certificate_subject_alternative_names
  route53_zone_id           = data.aws_route53_zone.main.zone_id
}

# WAF for CloudFront — CLOUDFRONT scope in us-east-1
module "waf_cloudfront" {
  source = "../../modules/waf"

  providers = {
    aws = aws.us_east_1
  }

  name_prefix        = local.name_prefix
  scope              = "CLOUDFRONT"
  rate_limit         = var.waf_cloudfront_rate_limit
  log_retention_days = var.waf_log_retention_days
}

# WAF for AppSync — REGIONAL scope in the main region
module "waf_regional" {
  source = "../../modules/waf"

  name_prefix        = local.name_prefix
  scope              = "REGIONAL"
  rate_limit         = var.waf_regional_rate_limit
  log_retention_days = var.waf_log_retention_days
}

# WAF for API Gateway — REGIONAL scope
module "waf_api_gateway" {
  source = "../../modules/waf"

  name_prefix                = "${local.name_prefix}-apigw"
  scope                      = "REGIONAL"
  rate_limit                 = var.waf_cloudfront_rate_limit
  log_retention_days         = var.waf_log_retention_days
  origin_verify_header_value = random_password.origin_verify_secret.result
}

resource "aws_wafv2_web_acl_association" "public_api" {
  resource_arn = module.api_gateway.public_stage_arn
  web_acl_arn  = module.waf_api_gateway.web_acl_arn
}

resource "aws_wafv2_web_acl_association" "private_api" {
  resource_arn = module.api_gateway_private.private_stage_arn
  web_acl_arn  = module.waf_api_gateway.web_acl_arn
}

# ACM certificate for AppSync
module "acm_regional" {
  source = "../../modules/acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name_prefix               = "${local.name_prefix}-regional"
  domain_name               = var.appsync_custom_domain
  subject_alternative_names = []
  route53_zone_id           = data.aws_route53_zone.main.zone_id
}

module "appsync_domain" {
  source = "../../modules/appsync_domain"

  name_prefix     = local.name_prefix
  appsync_api_id  = module.appsync.api_id
  appsync_api_arn = module.appsync.api_arn
  domain_name     = var.appsync_custom_domain
  certificate_arn = module.acm_regional.certificate_arn
  waf_web_acl_arn = module.waf_regional.web_acl_arn
  route53_zone_id = data.aws_route53_zone.main.zone_id
}

