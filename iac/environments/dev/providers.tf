provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = local.default_tags
  }
}

/* provider "kafka" {
  bootstrap_servers = ["${module.data_layer.msk_bootstrap_brokers_sasl_iam}"]
  tls_enabled       = true
  sasl_mechanism    = "aws-iam"
  sasl_aws_region   = var.aws_region
  sasl_aws_profile  = var.aws_profile
} */
