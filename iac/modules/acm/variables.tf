variable "name_prefix" {
  description = "Prefix used for resource names and tags"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name for the certificate (e.g. galaxymorph.com)"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domains to include in the certificate (e.g. *.galaxymorph.com)"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID used to create DNS validation records"
  type        = string
}
