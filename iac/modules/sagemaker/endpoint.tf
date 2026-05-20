resource "aws_sagemaker_model" "galaxy_classifier" {
  count = var.enable_sagemaker_endpoint ? 1 : 0

  name               = "${var.name_prefix}-galaxy-classifier"
  execution_role_arn = var.execution_role_arn

  primary_container {
    image          = var.image_uri
    model_data_url = var.model_artifact_s3_uri

    environment = {
      SAGEMAKER_PROGRAM = "inference.py"
    }
  }

  dynamic "vpc_config" {
    for_each = var.enable_vpc_config ? [1] : []
    content {
      subnets            = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }
}

resource "aws_sagemaker_endpoint_configuration" "galaxy_classifier" {
  count = var.enable_sagemaker_endpoint ? 1 : 0

  name = "${var.name_prefix}-galaxy-classifier"

  production_variants {
    variant_name           = "primary"
    model_name             = aws_sagemaker_model.galaxy_classifier[0].name
    initial_instance_count = var.initial_instance_count
    instance_type          = var.instance_type
    initial_variant_weight = 1
  }
}

resource "aws_sagemaker_endpoint" "galaxy_classifier" {
  count = var.enable_sagemaker_endpoint ? 1 : 0

  name                 = "${var.name_prefix}-galaxy-classifier"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.galaxy_classifier[0].name
}
