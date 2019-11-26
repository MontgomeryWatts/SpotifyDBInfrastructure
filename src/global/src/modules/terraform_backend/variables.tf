variable "bucket_name" {
  type        = "string"
  description = "The name of the bucket to create"
}

variable "enable_versioning" {
  type        = "string"
  default     = false
  description = "Whether versioning should be enabled on the s3 backend"
}

variable "terraform_arn" {
  type        = "string"
  description = "The ARN of the terraform user to access the remote backend"
}