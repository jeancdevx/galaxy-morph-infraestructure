resource "aws_emrserverless_application" "streaming" {
  name          = "${var.name_prefix}-streaming"
  release_label = var.release_label
  type          = var.application_type

  auto_start_configuration {
    enabled = var.auto_start_enabled
  }

  auto_stop_configuration {
    enabled              = var.auto_stop_enabled
    idle_timeout_minutes = var.idle_timeout_minutes
  }

  dynamic "initial_capacity" {
    for_each = var.enable_initial_capacity ? ["Driver"] : []

    content {
      initial_capacity_type = "Driver"

      initial_capacity_config {
        worker_count = var.initial_driver_worker_count

        worker_configuration {
          cpu    = var.initial_driver_cpu
          memory = var.initial_driver_memory
        }
      }
    }
  }

  dynamic "initial_capacity" {
    for_each = var.enable_initial_capacity ? ["Executor"] : []

    content {
      initial_capacity_type = "Executor"

      initial_capacity_config {
        worker_count = var.initial_executor_worker_count

        worker_configuration {
          cpu    = var.initial_executor_cpu
          memory = var.initial_executor_memory
        }
      }
    }
  }

  maximum_capacity {
    cpu    = var.maximum_cpu
    memory = var.maximum_memory
    disk   = var.maximum_disk
  }

  network_configuration {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.emr_security_group_id]
  }

  monitoring_configuration {
    cloudwatch_logging_configuration {
      enabled                = true
      log_group_name         = aws_cloudwatch_log_group.emr_serverless.name
      log_stream_name_prefix = "applications"
    }

    s3_monitoring_configuration {
      log_uri = local.s3_log_uri
    }
  }

  tags = {
    Name = "${var.name_prefix}-streaming"
    Tier = "compute"
  }
}
