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

variable "datalake_bucket_name" {
  type        = "string"
  description = "The name of the S3 bucket that acts as the datalake"
  default     = "spotifydb-datalake"
}

variable "terraform_arn" {
  type        = "string"
  description = "The ARN of the terraform user to access the remote backend"
}

variable "spotify_id" {
  type        = "string"
  description = "The (secret) client id required to connect to Spotify"
}

variable "spotify_secret" {
  type        = "string"
  description = "The client secret required to connect to Spotify"
}

variable "mongodb_atlas_public_key" {
  type = "string"
}

variable "mongodb_atlas_private_key" {
  type = "string"
}

variable "mongodb_atlas_organization_id" {
  description = "The ID of your MongoDB Atlas Organization. Unclear if this should be secret so being safe."
}

variable "mongodb_uri" {
  type = "string"
  description = "The URI to connect to MongoDB Atlas with"
}