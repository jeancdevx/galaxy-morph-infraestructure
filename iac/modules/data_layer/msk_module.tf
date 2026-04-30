module "msk" {
  source = "./msk"

  name_prefix           = var.name_prefix
  private_subnet_ids    = var.private_subnet_ids
  msk_security_group_id = var.msk_security_group_id
  msk_cluster_name      = var.msk_cluster_name
}
