variable "aws_region" {
  type        = "string"
  default     = "us-east-1"
  description = "What AWS Region to provision resources in"
}

variable "mongodb_atlas_organization_id" {
  description = "The ID of your MongoDB Atlas Organization. Unclear if this should be secret so being safe."
}

variable "bucket_name" {
  type = "string"
  description = "The name of the S3 Bucket to retrieve entities from"
}



variable "mongodb_atlas_public_key" {

}

variable "mongodb_atlas_private_key" {

}

