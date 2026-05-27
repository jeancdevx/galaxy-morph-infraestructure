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

data "aws_iam_policy_document" "kafka_ui_msk_access" {
  statement {
    sid = "MSKClusterConnect"

    actions = [
      "kafka-cluster:Connect",
      "kafka-cluster:DescribeCluster",
      "kafka-cluster:DescribeClusterDynamicConfiguration",
      "kafka-cluster:AlterCluster",
      "kafka-cluster:AlterClusterDynamicConfiguration",
    ]

    resources = [var.msk_cluster_arn]
  }

  statement {
    sid = "MSKTopicManage"

    actions = [
      "kafka-cluster:DescribeTopic",
      "kafka-cluster:DescribeTopicDynamicConfiguration",
      "kafka-cluster:CreateTopic",
      "kafka-cluster:AlterTopic",
      "kafka-cluster:AlterTopicDynamicConfiguration",
      "kafka-cluster:DeleteTopic",
      "kafka-cluster:ReadData",
      "kafka-cluster:WriteData",
    ]

    resources = [var.msk_topic_arn_prefix]
  }

  statement {
    sid = "MSKGroupManage"

    actions = [
      "kafka-cluster:DescribeGroup",
      "kafka-cluster:AlterGroup",
      "kafka-cluster:DeleteGroup",
    ]

    resources = [var.msk_group_arn_prefix]
  }
}

resource "aws_iam_policy" "kafka_ui_msk_access" {
  name        = "${var.name_prefix}-kafka-ui-msk-access"
  description = "Allow Kafka UI to connect and read/write to MSK Serverless"
  policy      = data.aws_iam_policy_document.kafka_ui_msk_access.json
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
