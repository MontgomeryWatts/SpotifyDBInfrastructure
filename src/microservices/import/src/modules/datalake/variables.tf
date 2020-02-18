variable "bucket_name" {
  type        = "string"
  description = "The name of the bucket to create"
}

variable "producer_arns" {
  type        = "list"
  description = "The ARNs of the resources to allow PUT access for"
}

variable "consumer_arns" {
  type        = "list"
  description = "The ARNS of resources allowed to GET from the datalake"
  default     = []
}
