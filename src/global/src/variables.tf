variable "aws_region" {
  type        = "string"
  description = "What AWS Region to provision resources in"
}

variable "site_url" {
  type        = "string"
  description = "The URL of the main website"
}

variable "environment" {
  type        = "string"
  description = "The environment to provision resources for"
}

variable "remote_backend_bucket_name" {
  type        = "string"
  description = "The name of the bucket to store the remote state in"
}


variable "terraform_arn" {
  type        = "string"
  description = "The ARN of the terraform user to access the remote backend"
}
