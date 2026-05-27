resource "aws_dynamodb_table" "terraform_lock" {
  #checkov:skip=CKV_AWS_119:DynamoDB default encryption at rest is sufficient for Terraform state lock table in dev
  name         = var.state_lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }
}
