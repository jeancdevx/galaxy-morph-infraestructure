resource "aws_cognito_user_pool" "pool" {

  name = "${var.name_prefix}-user-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_uppercase                = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  schema {
    name                = "email"
    required            = true
    mutable             = true
    attribute_data_type = "String"
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  verification_message_template {
    email_subject = "${var.app_email_subject} - Verify your email"
    email_message = "Your verification code is {####}"
  }

}


