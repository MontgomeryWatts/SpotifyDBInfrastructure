variable "source_bucket_name" {
  type        = "string"
  description = "The S3 bucket containing the source code for the lambda"
}

variable "lambda_name" {
  type        = "string"
  description = "The name of the AWS Lambda to create"
}

variable "handler_name" {
  type        = "string"
  description = "The name of the handler for the AWS Lambda to call"
}

variable "dynamodb_table_arn" {
  type        = "string"
  description = "The ARN of the DynamoDB table used to track updates"
}


variable "sns_topic_arn" {
  type        = "string"
  description = "The ARN of the SNS topic that orchestrates the import process"
}

variable "entity_types" {
  type        = "list"
  description = "The list of entity type strings to fiter SNS messages on"
}

variable "lambda_timeout_seconds" {
  type        = "string"
  description = "How many seconds the lambda may execute before timing out"
}

variable "lambda_runtime" {
  type        = "string"
  description = "A version of a programming language that AWS lambda supports"
}

variable "lambda_memory_size" {
  type        = "string"
  description = "How much memory to provision for the lambda in MB"
}

variable "lambda_file_name" {
  type        = "string"
  description = "The name of the deployment package file"
}

variable "lambda_environment_variables" {
  type        = "map"
  description = "The environment variables to provide to the lamdba"
}

variable "messages_per_lambda_invocation" {
  type        = "string"
  description = "Integer defining how many sqs messages should be processed at a time"
}
