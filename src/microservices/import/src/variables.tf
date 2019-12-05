variable "aws_region" {
  type        = "string"
  default     = "us-east-1"
  description = "What AWS Region to provision resources in"
}

variable "spotify_id" {
  type        = "string"
  description = "The (secret) client id required to connect to Spotify"
}

variable "spotify_secret" {
  type        = "string"
  description = "The client secret required to connect to Spotify"
}

variable "bucket_name" {
  type        = "string"
  description = "The S3 bucket to place artists in"
}