locals {
  results_dispatcher_zip = "${path.module}/../../../services/lambdas/results_dispatcher/dist/function.zip"
}

resource "aws_lambda_function" "results_dispatcher" {
  function_name = "${var.name_prefix}-results-dispatcher"
  role          = var.results_dispatcher_role_arn
  runtime       = "nodejs22.x"
  handler       = "index.handler"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  filename         = local.results_dispatcher_zip
  source_code_hash = try(filebase64sha256(local.results_dispatcher_zip), null)

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_private_sg_id]
  }

  environment {
    variables = {
      JOBS_TABLE_NAME         = var.jobs_table_name
      APPSYNC_GRAPHQL_URL     = var.appsync_graphql_url
      POWERTOOLS_SERVICE_NAME = "results-dispatcher"
      LOG_LEVEL               = "INFO"
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [aws_cloudwatch_log_group.results_dispatcher]
}

resource "aws_lambda_event_source_mapping" "results_topic" {
  event_source_arn  = var.msk_cluster_arn
  function_name     = aws_lambda_function.results_dispatcher.arn
  topics            = [var.results_topic_name]
  starting_position = "TRIM_HORIZON"

  batch_size                         = 100
  maximum_batching_window_in_seconds = 5

  dynamic "destination_config" {
    for_each = var.dispatcher_dlq_arn != null ? [1] : []
    content {
      on_failure {
        destination_arn = var.dispatcher_dlq_arn
      }
    }
  }
}
