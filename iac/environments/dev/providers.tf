provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = local.default_tags
  }
}

# ACM certificates for CloudFront must reside in us-east-1 (CloudFront is a global service).
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
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
