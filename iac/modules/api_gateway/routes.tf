resource "aws_api_gateway_method" "signup_post" {
  rest_api_id   = aws_api_gateway_rest_api.public.id
  resource_id   = aws_api_gateway_resource.auth_signup.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "signup_post" {
  rest_api_id             = aws_api_gateway_rest_api.public.id
  resource_id             = aws_api_gateway_resource.auth_signup.id
  http_method             = aws_api_gateway_method.signup_post.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.auth_api.invoke_arn
}

resource "aws_api_gateway_method" "signin_post" {
  rest_api_id   = aws_api_gateway_rest_api.public.id
  resource_id   = aws_api_gateway_resource.auth_signin.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "signin_post" {
  rest_api_id             = aws_api_gateway_rest_api.public.id
  resource_id             = aws_api_gateway_resource.auth_signin.id
  http_method             = aws_api_gateway_method.signin_post.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.auth_api.invoke_arn
}

resource "aws_api_gateway_method" "history_get" {
  rest_api_id   = aws_api_gateway_rest_api.public.id
  resource_id   = aws_api_gateway_resource.classifications_history.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.querystring.limit"     = false
    "method.request.querystring.nextToken" = false
  }
}

resource "aws_api_gateway_integration" "history_get" {
  rest_api_id             = aws_api_gateway_rest_api.public.id
  resource_id             = aws_api_gateway_resource.classifications_history.id
  http_method             = aws_api_gateway_method.history_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.classification_api.invoke_arn
}
