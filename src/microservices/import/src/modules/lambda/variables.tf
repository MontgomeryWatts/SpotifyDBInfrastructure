variable "spotify_id" {
  type        = "string"
  description = "The (secret) client id required to connect to Spotify"
}

variable "spotify_secret" {
  type        = "string"
  description = "The client secret required to connect to Spotify"
}

variable "source_bucket_name" {
  type        = "string"
  description = "The S3 bucket containing the source code for the lambda"
}


variable "datalake_bucket_name" {
  type        = "string"
  description = "The S3 bucket to place data in"
}

variable "lambda_name" {
  type        = "string"
  description = "The name of the AWS Lambda to create"
}

variable "handler_name" {
  type        = "string"
  description = "The name of the handler for the AWS Lambda to call"
}

variable "sns_topic_arn" {
  type        = "string"
  description = "The ARN of the SNS topic that orchestrates the import process"
}

variable "entity_type" {
  type        = "string"
  description = "The type of entity to filter SNS messages on"
}