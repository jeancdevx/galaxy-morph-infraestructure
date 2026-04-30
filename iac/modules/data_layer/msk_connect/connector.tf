resource "aws_mskconnect_connector" "sqs_source" {
  count = var.enable_connector ? 1 : 0

  name                 = local.connector_name
  kafkaconnect_version = var.kafkaconnect_version

  capacity {
    autoscaling {
      mcu_count        = var.mcu_count
      min_worker_count = var.min_worker_count
      max_worker_count = var.max_worker_count

      scale_in_policy {
        cpu_utilization_percentage = 20
      }

      scale_out_policy {
        cpu_utilization_percentage = 80
      }
    }
  }

  connector_configuration = {
    "connector.class"                             = "org.apache.camel.kafkaconnector.aws2sqs.CamelAws2sqsSourceConnector"
    "tasks.max"                                   = tostring(var.tasks_max)
    "topics"                                      = var.ingestion_topic_name
    "camel.source.path.queueNameOrArn"            = var.ingestion_queue_arn
    "camel.source.endpoint.region"                = var.aws_region
    "camel.source.endpoint.useDefaultCredentialsProvider" = "true"
    "camel.source.endpoint.deleteAfterRead"       = "true"
    "camel.source.endpoint.maxMessagesPerPoll"    = "10"
    "value.converter"                             = "org.apache.kafka.connect.storage.StringConverter"
    "key.converter"                               = "org.apache.kafka.connect.storage.StringConverter"
    "behavior.on.error"                           = "log"
    "errors.tolerance"                            = "all"
    "errors.log.enable"                           = "true"
    "errors.log.include.messages"                 = "true"
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = var.msk_bootstrap_brokers_sasl_iam

      vpc {
        subnets         = var.private_subnet_ids
        security_groups = [var.msk_connect_security_group_id]
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "IAM"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "TLS"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.sqs_source.arn
      revision = aws_mskconnect_custom_plugin.sqs_source.latest_revision
    }
  }

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.connector[0].name
      }
    }
  }

  service_execution_role_arn = var.service_execution_role_arn

}
