resource "aws_sqs_queue" "ingestion_dlq" {
  #checkov:skip=CKV2_AWS_73:SSE-SQS (default encryption) is sufficient in dev; CMK adds cost without security benefit
  name = var.ingestion_dlq_name

  message_retention_seconds = 1209600

  tags = {
    Name = "${var.name_prefix}-ingestion-dlq"
    Tier = "data"
  }
}

resource "aws_sqs_queue" "ingestion" {
  #checkov:skip=CKV2_AWS_73:SSE-SQS (default encryption) is sufficient in dev; CMK adds cost without security benefit
  name                       = var.ingestion_queue_name
  visibility_timeout_seconds = var.ingestion_queue_visibility_timeout_seconds
  message_retention_seconds  = var.ingestion_queue_message_retention_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ingestion_dlq.arn
    maxReceiveCount     = var.ingestion_queue_max_receive_count
  })

  tags = {
    Name = "${var.name_prefix}-ingestion"
    Tier = "data"
  }
}
