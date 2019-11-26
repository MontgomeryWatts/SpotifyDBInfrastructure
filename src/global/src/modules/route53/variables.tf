variable "domain_validation_options" {
  type = "map"
}

variable "site_domain_name" {
  type        = "string"
  description = "The domain name of the main site"
}

variable "certificate_arn" {
  type        = "string"
  description = "The ARN of the SSL Certificate"
}


variable "cloudfront_domain_name" {
  type        = "string"
  description = "The domain name of the cloudfront distribution"
}

variable "cloudfront_hosted_zone_id" {
  type        = "string"
  description = "The hosted zone ID of the cloudfront distribution"
}

