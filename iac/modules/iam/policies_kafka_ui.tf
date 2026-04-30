resource "aws_iam_role" "kafka_ui_task" {
  name = "${var.name_prefix}-kafka-ui-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-kafka-ui-task-role"
  }
}

resource "aws_iam_policy" "kafka_ui_msk_access" {
  name        = "${var.name_prefix}-kafka-ui-msk-access"
  description = "Allow Kafka UI to connect and read/write to MSK Serverless"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeCluster",
          "kafka-cluster:DescribeClusterDynamicConfiguration",
          "kafka-cluster:AlterCluster",
          "kafka-cluster:AlterClusterDynamicConfiguration",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:DescribeTopicDynamicConfiguration",
          "kafka-cluster:CreateTopic",
          "kafka-cluster:AlterTopic",
          "kafka-cluster:AlterTopicDynamicConfiguration",
          "kafka-cluster:DeleteTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DeleteGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kafka_ui_msk_access" {
  role       = aws_iam_role.kafka_ui_task.name
  policy_arn = aws_iam_policy.kafka_ui_msk_access.arn
}

resource "aws_iam_role" "kafka_ui_execution" {
  name = "${var.name_prefix}-kafka-ui-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.name_prefix}-kafka-ui-exec-role"
  }
}

resource "aws_iam_role_policy_attachment" "kafka_ui_execution_basic" {
  role       = aws_iam_role.kafka_ui_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
