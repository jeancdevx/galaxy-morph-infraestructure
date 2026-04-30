variable "name_prefix" {
  description = "Prefix used to name MSK resources"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for MSK networking"
  type        = list(string)
}

variable "msk_security_group_id" {
  description = "Security group ID attached to MSK Serverless cluster"
  type        = string
}

variable "msk_cluster_name" {
  description = "Optional MSK Serverless cluster name"
  type        = string
  default     = null
  nullable    = true
}
