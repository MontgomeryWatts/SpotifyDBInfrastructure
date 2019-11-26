variable "certificate_arn" {
  type        = "string"
  description = "The ARN of the SSL Certificate"
}

variable "bucket_domain_name" {
  type        = "string"
  description = "The domain name of the S3 bucket hosting the static site"
}

variable "bucket_origin_id" {
  type        = "string"
  description = "The ID of the S3 bucket origin"
}

variable "aliases" {
  type        = "list"
  description = "Alternate domain names for the CloudFront distribution"
}
