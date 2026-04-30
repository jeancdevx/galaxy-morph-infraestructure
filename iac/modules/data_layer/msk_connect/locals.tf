locals {
  connector_name = "${var.name_prefix}-sqs-source"
  log_group_name = "/aws/mskconnect/${local.connector_name}"
}
