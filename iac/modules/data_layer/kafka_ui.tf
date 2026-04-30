resource "aws_ecs_cluster" "kafka_ui" {
  name = "${var.name_prefix}-kafka-ui"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "kafka_ui" {
  name              = "/ecs/${var.name_prefix}-kafka-ui"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "kafka_ui" {
  family                   = "${var.name_prefix}-kafka-ui"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = var.kafka_ui_execution_role_arn
  task_role_arn            = var.kafka_ui_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "kafka-ui"
      image     = "provectuslabs/kafka-ui:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "KAFKA_CLUSTERS_0_NAME"
          value = "galaxy-kafka"
        },
        {
          name  = "KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS"
          value = module.msk.msk_bootstrap_brokers_sasl_iam
        },
        {
          name  = "KAFKA_CLUSTERS_0_PROPERTIES_SECURITY_PROTOCOL"
          value = "SASL_SSL"
        },
        {
          name  = "KAFKA_CLUSTERS_0_PROPERTIES_SASL_MECHANISM"
          value = "AWS_MSK_IAM"
        },
        {
          name  = "KAFKA_CLUSTERS_0_PROPERTIES_SASL_JAAS_CONFIG"
          value = "software.amazon.msk.auth.iam.IAMLoginModule required;"
        },
        {
          name  = "KAFKA_CLUSTERS_0_PROPERTIES_SASL_CLIENT_CALLBACK_HANDLER_CLASS"
          value = "software.amazon.msk.auth.iam.IAMClientCallbackHandler"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.kafka_ui.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "kafka_ui" {
  name            = "${var.name_prefix}-kafka-ui"
  cluster         = aws_ecs_cluster.kafka_ui.id
  task_definition = aws_ecs_task_definition.kafka_ui.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [aws_security_group.kafka_ui.id]
    assign_public_ip = true
  }
}

resource "aws_security_group" "kafka_ui" {
  name        = "${var.name_prefix}-kafka-ui-sg"
  description = "Security Group for Kafka UI Fargate task"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP inbound"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-kafka-ui-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "msk_from_kafka_ui" {
  security_group_id            = var.msk_security_group_id
  referenced_security_group_id = aws_security_group.kafka_ui.id
  from_port                    = 9098
  to_port                      = 9098
  ip_protocol                  = "tcp"
  description                  = "Allow Kafka UI to connect to MSK"
}
