output "terraform_state_bucket_name" {
  description = "S3 bucket name used for Terraform remote state"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_lock_table_name" {
  description = "DynamoDB table name used for Terraform state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "backend_config_example" {
  description = "Example backend values to place in environment backend.hcl files"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    dynamodb_table = aws_dynamodb_table.terraform_lock.name
    region         = var.aws_region
    encrypt        = true
  }
}
