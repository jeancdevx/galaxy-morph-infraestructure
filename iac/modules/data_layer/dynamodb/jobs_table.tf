resource "aws_dynamodb_table" "jobs" {
  name         = var.jobs_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.jobs_table_hash_key
  range_key    = var.jobs_table_range_key

  attribute {
    name = var.jobs_table_hash_key
    type = "S"
  }

  attribute {
    name = var.jobs_table_range_key
    type = "S"
  }

  dynamic "attribute" {
    for_each = var.enable_gsi_client_status ? [1] : []
    content {
      name = "clientId"
      type = "S"
    }
  }

  dynamic "attribute" {
    for_each = var.enable_gsi_client_status ? [1] : []
    content {
      name = "status"
      type = "S"
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.enable_gsi_client_status ? [1] : []
    content {
      name = "clientId-status-index"
      key_schema {
        attribute_name = "clientId"
        key_type       = "HASH"
      }
      key_schema {
        attribute_name = "status"
        key_type       = "RANGE"
      }
      projection_type = "ALL"
    }
  }

  ttl {
    attribute_name = "ttl"
    enabled        = var.enable_ttl
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  tags = {
    Name = "${var.name_prefix}-jobs-table"
    Tier = "data"
  }
}
