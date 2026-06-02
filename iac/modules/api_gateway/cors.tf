locals {
  cors_allow_headers = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key'"
}

resource "aws_api_gateway_method" "auth_signup_options" {
  rest_api_id   = aws_api_gateway_rest_api.public.id
  resource_id   = aws_api_gateway_resource.auth_signup.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_signup_options" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  resource_id = aws_api_gateway_resource.auth_signup.id
  http_method = aws_api_gateway_method.auth_signup_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "auth_signup_options" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  resource_id = aws_api_gateway_resource.auth_signup.id
  http_method = aws_api_gateway_method.auth_signup_options.http_method
  status_code = "200"

  response_models = { "application/json" = "Empty" }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "auth_signup_options" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  resource_id = aws_api_gateway_resource.auth_signup.id
  http_method = aws_api_gateway_method.auth_signup_options.http_method
  status_code = aws_api_gateway_method_response.auth_signup_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = local.cors_allow_headers
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.auth_signup_options]
}

resource "aws_api_gateway_method" "auth_signin_options" {
  rest_api_id   = aws_api_gateway_rest_api.public.id
  resource_id   = aws_api_gateway_resource.auth_signin.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_signin_options" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  resource_id = aws_api_gateway_resource.auth_signin.id
  http_method = aws_api_gateway_method.auth_signin_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "auth_signin_options" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  resource_id = aws_api_gateway_resource.auth_signin.id
  http_method = aws_api_gateway_method.auth_signin_options.http_method
  status_code = "200"

  response_models = { "application/json" = "Empty" }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "auth_signin_options" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  resource_id = aws_api_gateway_resource.auth_signin.id
  http_method = aws_api_gateway_method.auth_signin_options.http_method
  status_code = aws_api_gateway_method_response.auth_signin_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = local.cors_allow_headers
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.auth_signin_options]
}

resource "aws_api_gateway_method" "history_options" {
  rest_api_id   = aws_api_gateway_rest_api.public.id
  resource_id   = aws_api_gateway_resource.classifications_history.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "history_options" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  resource_id = aws_api_gateway_resource.classifications_history.id
  http_method = aws_api_gateway_method.history_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "history_options" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  resource_id = aws_api_gateway_resource.classifications_history.id
  http_method = aws_api_gateway_method.history_options.http_method
  status_code = "200"

  response_models = { "application/json" = "Empty" }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "history_options" {
  rest_api_id = aws_api_gateway_rest_api.public.id
  resource_id = aws_api_gateway_resource.classifications_history.id
  http_method = aws_api_gateway_method.history_options.http_method
  status_code = aws_api_gateway_method_response.history_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = local.cors_allow_headers
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.history_options]
}

resource "aws_api_gateway_gateway_response" "cors_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.public.id
  response_type = "DEFAULT_4XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = local.cors_allow_headers
  }
}

resource "aws_api_gateway_gateway_response" "cors_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.public.id
  response_type = "DEFAULT_5XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = local.cors_allow_headers
  }
}
