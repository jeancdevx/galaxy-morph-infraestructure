data "aws_caller_identity" "current" {}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix          = "${var.project_name}-${var.environment}"
  region_prefix        = var.aws_region
  vpc_cidr_block       = var.vpc_cidr_block
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
}

module "security_groups" {
  source = "../../modules/security_groups"

  name_prefix          = "${var.project_name}-${var.environment}"
  vpc_id               = module.vpc.vpc_id
  msk_port             = var.msk_port
  sagemaker_https_port = var.sagemaker_https_port
}

module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  name_prefix             = "${var.project_name}-${var.environment}"
  aws_region              = var.aws_region
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  private_route_table_ids = module.vpc.private_route_table_ids
  endpoint_security_group_ids = [
    module.security_groups.lambda_private_sg_id,
    module.security_groups.emr_sg_id,
    module.security_groups.sagemaker_endpoint_sg_id,
  ]

  enable_s3_gateway_endpoint                  = var.enable_s3_gateway_endpoint
  enable_dynamodb_gateway_endpoint            = var.enable_dynamodb_gateway_endpoint
  enable_sqs_interface_endpoint               = var.enable_sqs_interface_endpoint
  enable_sagemaker_runtime_interface_endpoint = var.enable_sagemaker_runtime_interface_endpoint
  enable_private_dns                          = var.enable_private_dns
}

module "iam" {
  source = "../../modules/iam"

  name_prefix    = "${var.project_name}-${var.environment}"
  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id

  jobs_table_name         = var.jobs_table_name
  images_bucket_name      = var.images_bucket_name
  checkpoints_bucket_name = var.checkpoints_bucket_name
  models_bucket_name      = var.models_bucket_name
  raw_bucket_name         = var.raw_bucket_name

  appsync_api_arn = var.appsync_api_arn
  msk_cluster_arn = var.msk_cluster_arn
}

module "cognito" {
  source = "../../modules/cognito"

  name_prefix       = "${var.project_name}-${var.environment}"
  app_email_subject = var.project_name
}
