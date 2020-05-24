variable "aws_region" {
  type        = "string"
  description = "What AWS Region to provision resources in"
  default     = "us-east-1"
}

variable "site_url" {
  type        = "string"
  description = "The URL that the frontend is served from"
  default     = "spotifydb.com"
}

variable "remote_state_bucket_name" {
  type        = "string"
  description = "The name of the S3 bucket the remote state is stored in"
  default     = "spotifydb-remote-state"
}

variable "terraform_arn" {
  type        = "string"
  description = "The ARN of the terraform user to access the remote backend"
}