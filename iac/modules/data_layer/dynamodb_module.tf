module "dynamodb" {
  source = "./dynamodb"

  name_prefix                       = var.name_prefix
  jobs_table_name                   = var.jobs_table_name
  jobs_table_hash_key               = var.jobs_table_hash_key
  jobs_table_range_key              = var.jobs_table_range_key
  enable_point_in_time_recovery     = var.enable_point_in_time_recovery
  enable_ttl                        = var.enable_ttl
  enable_gsi_client_status          = var.enable_gsi_client_status
  enable_gsi_entity_type_created_at = var.enable_gsi_entity_type_created_at
}
