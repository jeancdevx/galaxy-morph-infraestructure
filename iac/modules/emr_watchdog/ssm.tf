resource "aws_ssm_parameter" "emr_job_run_id" {
  name  = "/${var.name_prefix}/emr/current-job-run-id"
  type  = "String"
  value = "none"

  lifecycle {
    ignore_changes = [value]
  }
}
