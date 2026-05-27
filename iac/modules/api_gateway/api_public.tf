resource "aws_api_gateway_rest_api" "public" {
  name = "${var.name_prefix}-public-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  parent_id   = aws_api_gateway_rest_api.public.root_resource_id
  path_part   = "auth"
}

resource "aws_api_gateway_resource" "auth_signup" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "signup"
}

resource "aws_api_gateway_resource" "auth_signin" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "signin"
}

resource "aws_api_gateway_resource" "classifications" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  parent_id   = aws_api_gateway_rest_api.public.root_resource_id
  path_part   = "classifications"
}

resource "aws_api_gateway_resource" "classifications_history" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  parent_id   = aws_api_gateway_resource.classifications.id
  path_part   = "history"
}

resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${var.name_prefix}-cognito"
  rest_api_id     = aws_api_gateway_rest_api.public.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [var.cognito_user_pool_arn]
  identity_source = "method.request.header.Authorization"
}
