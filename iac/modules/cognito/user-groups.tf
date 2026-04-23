resource "aws_cognito_user_group" "public_user_group" {
  user_pool_id = aws_cognito_user_pool.pool.id
  name         = "public-user"
  description  = "Group for public users"
}

resource "aws_cognito_user_group" "scientist_user_group" {
  user_pool_id = aws_cognito_user_pool.pool.id
  name         = "scientist-user"
  description  = "Group for scientist users"
}
