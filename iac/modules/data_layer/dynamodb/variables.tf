variable "name_prefix" {
  description = "Prefix used to name DynamoDB resources"
  type        = string
}

variable "jobs_table_name" {
  description = "DynamoDB jobs table name"
  type        = string
}

variable "jobs_table_hash_key" {
  description = "DynamoDB partition key attribute name"
  type        = string
}

variable "jobs_table_range_key" {
  description = "DynamoDB sort key attribute name"
  type        = string
}

variable "enable_point_in_time_recovery" {
  description = "Enable PITR on jobs table"
  type        = bool
}

variable "enable_ttl" {
  description = "Enable TTL on jobs table for auto-cleanup of old records"
  type        = bool
  default     = true
}

variable "enable_gsi_client_status" {
  description = "Enable GSI clientId-status-index for querying jobs by scientist"
  type        = bool
  default     = true
}

variable "enable_gsi_entity_type_created_at" {
  description = "Enable GSI entityType-createdAt-index for the global community classification feed"
  type        = bool
  default     = true
}
