resource "aws_appautoscaling_target" "sagemaker_variant" {
  count = var.enable_sagemaker_endpoint && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "endpoint/${aws_sagemaker_endpoint.galaxy_classifier[0].name}/variant/primary"
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"
}

resource "aws_appautoscaling_policy" "invocations" {
  count = var.enable_sagemaker_endpoint && var.enable_autoscaling ? 1 : 0

  name               = "${var.name_prefix}-sagemaker-invocations"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.sagemaker_variant[0].resource_id
  scalable_dimension = aws_appautoscaling_target.sagemaker_variant[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.sagemaker_variant[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_target_invocations
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "SageMakerVariantInvocationsPerInstance"
    }
  }
}
