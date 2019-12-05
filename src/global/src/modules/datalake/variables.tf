variable "bucket_name" {
  type        = "string"
  description = "The name of the bucket to create"
}

variable "import_lambda_role_arns" {
  type        = "list"
  description = "The arns of the roles to allow PUT access for"
}