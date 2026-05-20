resource "aws_cloudwatch_metric_alarm" "invocations_5xx" {
  count = var.enable_sagemaker_endpoint ? 1 : 0

  alarm_name          = "${var.name_prefix}-sagemaker-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Invocation5XXErrors"
  namespace           = "AWS/SageMaker"
  period              = 60
  statistic           = "Sum"
  threshold           = var.error_alarm_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.galaxy_classifier[0].name
    VariantName  = "primary"
  }
}

resource "aws_cloudwatch_metric_alarm" "model_latency_p99" {
  count = var.enable_sagemaker_endpoint ? 1 : 0

  alarm_name          = "${var.name_prefix}-sagemaker-latency-p99"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ModelLatency"
  namespace           = "AWS/SageMaker"
  period              = 60
  extended_statistic  = "p99"
  threshold           = var.latency_alarm_threshold_us
  treat_missing_data  = "notBreaching"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.galaxy_classifier[0].name
    VariantName  = "primary"
  }
}
