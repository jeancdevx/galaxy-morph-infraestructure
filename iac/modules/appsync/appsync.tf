resource "aws_appsync_graphql_api" "main" {
  name                = "${var.name_prefix}-api"
  authentication_type = "AMAZON_COGNITO_USER_POOLS"

  user_pool_config {
    user_pool_id   = var.cognito_user_pool_id
    aws_region     = var.aws_region
    default_action = "ALLOW"
  }

  additional_authentication_provider {
    authentication_type = "AWS_IAM"
  }

  schema = file("${path.module}/schema.graphql")

  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logging.arn
    field_log_level          = "ERROR"
    exclude_verbose_content  = true
  }

  tags = {
    Name = "${var.name_prefix}-appsync"
    Tier = "api"
  }
}

resource "aws_appsync_datasource" "none" {
  api_id = aws_appsync_graphql_api.main.id
  name   = "NoneDataSource"
  type   = "NONE"
}

resource "aws_appsync_resolver" "notify_classification" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "notifyClassification"
  data_source = aws_appsync_datasource.none.name

  request_template = <<-VTL
    {
      "version": "2018-05-29",
      "payload": $util.toJson($context.arguments.input)
    }
  VTL

  response_template = <<-VTL
    $util.toJson($context.result)
  VTL
}

resource "aws_appsync_resolver" "on_classification" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Subscription"
  field       = "onClassification"
  data_source = aws_appsync_datasource.none.name

  request_template = <<-VTL
    #if($context.identity.claims.sub != $context.args.clientId)
      $util.unauthorized()
    #end
    {
      "version": "2018-05-29",
      "payload": {}
    }
  VTL

  response_template = <<-VTL
    null
  VTL
}
