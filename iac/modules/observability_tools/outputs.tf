output "kafka_ui_cluster_id" {
  description = "ECS cluster ID for the Kafka UI service"
  value       = aws_ecs_cluster.kafka_ui.id
}

output "kafka_ui_service_name" {
  description = "ECS service name for the Kafka UI task"
  value       = aws_ecs_service.kafka_ui.name
}

output "kafka_ui_security_group_id" {
  description = "Security group ID attached to the Kafka UI Fargate task"
  value       = aws_security_group.kafka_ui.id
}
