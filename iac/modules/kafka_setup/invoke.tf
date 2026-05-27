resource "aws_lambda_invocation" "kafka_setup" {
  function_name = aws_lambda_function.kafka_setup.function_name

  triggers = {
    redeployment = aws_lambda_function.kafka_setup.source_code_hash
  }

  input = jsonencode({})
}
