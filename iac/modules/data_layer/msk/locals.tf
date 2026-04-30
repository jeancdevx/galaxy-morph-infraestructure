locals {
  cluster_name = var.msk_cluster_name != null && var.msk_cluster_name != "" ? var.msk_cluster_name : "${var.name_prefix}-msk-serverless"
}
