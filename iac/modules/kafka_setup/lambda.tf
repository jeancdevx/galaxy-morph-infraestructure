locals {
  kafka_setup_zip = "${path.module}/../../../services/lambdas/kafka_setup/dist/function.zip"
}

resource "aws_lambda_function" "kafka_setup" {
  #checkov:skip=CKV_AWS_116:Lambda is invoked synchronously by Terraform; DLQ not applicable
  #checkov:skip=CKV_AWS_173:Environment variables are MSK endpoints and topic names, not secrets
  function_name = "${var.name_prefix}-kafka-setup"
  role          = var.execution_role_arn
  runtime       = "python3.12"
  handler       = "index.handler"
  timeout       = 120
  memory_size   = 256

  filename         = local.kafka_setup_zip
  source_code_hash = try(filebase64sha256(local.kafka_setup_zip), null)

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_private_sg_id]
  }

  environment {
    variables = {
      KAFKA_BOOTSTRAP_SERVERS  = var.kafka_bootstrap_servers
      INGESTION_TOPIC_NAME     = var.ingestion_topic_name
      RESULTS_TOPIC_NAME       = var.results_topic_name
      TOPIC_PARTITIONS         = tostring(var.topic_partitions)
      TOPIC_REPLICATION_FACTOR = tostring(var.topic_replication_factor)
      INGESTION_RETENTION_MS   = tostring(var.ingestion_retention_ms)
      RESULTS_RETENTION_MS     = tostring(var.results_retention_ms)
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [aws_cloudwatch_log_group.kafka_setup]
}
