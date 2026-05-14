variable "images_bucket_name" {
  description = "Name of the S3 bucket for galaxy images"
  type        = string
}

variable "checkpoints_bucket_name" {
  description = "Name of the S3 bucket for Spark checkpoints and EMR logs"
  type        = string
}

variable "models_bucket_name" {
  description = "Name of the S3 bucket for ML model artifacts"
  type        = string
}
