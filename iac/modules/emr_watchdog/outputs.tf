output "launcher_function_name" {
  description = "Name of the EMR job launcher Lambda"
  value       = aws_lambda_function.emr_job_launcher.function_name
}

output "watchdog_function_name" {
  description = "Name of the EMR job watchdog Lambda"
  value       = aws_lambda_function.emr_job_watchdog.function_name
}

output "ssm_job_run_id_parameter_name" {
  description = "SSM parameter name holding the current EMR job run ID"
  value       = aws_ssm_parameter.emr_job_run_id.name
}
