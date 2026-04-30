module "msk_connect" {
  source = "./msk_connect"

  enable_connector               = var.enable_msk_connect_connector
  name_prefix                    = var.name_prefix
  aws_region                     = var.aws_region
  private_subnet_ids             = var.private_subnet_ids
  msk_connect_security_group_id  = var.msk_connect_security_group_id
  msk_bootstrap_brokers_sasl_iam = module.msk.msk_bootstrap_brokers_sasl_iam
  service_execution_role_arn     = var.msk_connect_execution_role_arn
  raw_bucket_name                = var.raw_bucket_name
  raw_bucket_arn                 = var.raw_bucket_arn
  ingestion_queue_arn            = module.sqs.ingestion_queue_arn
  ingestion_topic_name           = var.ingestion_topic_name
  kafkaconnect_version           = var.msk_connect_kafkaconnect_version
  mcu_count                      = var.msk_connect_mcu_count
  min_worker_count               = var.msk_connect_min_worker_count
  max_worker_count               = var.msk_connect_max_worker_count
  tasks_max                      = var.msk_connect_tasks_max
  cloudwatch_log_retention_days  = var.msk_connect_log_retention_days
}
