resource "aws_cognito_user_pool_client" "frontend_client" {
  name         = "${var.name_prefix}-frontend-client"
  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
}
