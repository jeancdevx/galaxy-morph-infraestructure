module "sqs" {
  source = "./sqs"

  name_prefix                                = var.name_prefix
  ingestion_queue_name                       = var.ingestion_queue_name
  ingestion_dlq_name                         = var.ingestion_dlq_name
  ingestion_queue_visibility_timeout_seconds = var.ingestion_queue_visibility_timeout_seconds
  ingestion_queue_message_retention_seconds  = var.ingestion_queue_message_retention_seconds
  ingestion_queue_max_receive_count          = var.ingestion_queue_max_receive_count
}
