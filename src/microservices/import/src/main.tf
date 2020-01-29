provider "aws" {
  version = "~> 2.0"
  profile = "terraform-user"
  region  = "${var.aws_region}"
}

terraform {
  backend "s3" { # Backend configurations can't have interpolations
    bucket  = "spotifydb-remote-state"
    key     = "microservices/import/terraform.tfstate"
    region  = "us-east-1"
    profile = "terraform-user"
  }
}

locals {
  spotify_environment_variables = {
    SPOTIFY_ID     = "${var.spotify_id}"
    SPOTIFY_SECRET = "${var.spotify_secret}"
  }
  import_environment_variables = "${merge(local.spotify_environment_variables, {
    BUCKET_NAME = "${var.bucket_name}"
  })}"

  fan_out_environment_variables = "${merge(local.spotify_environment_variables, {
    TOPIC_ARN = "${module.import-orchestration-topic.sns_topic_arn}"
  })}"
}


resource "aws_s3_bucket" "bucket" {
  bucket = "spotifydb-import-lambdas"
}

module "datalake" {
  source        = "./modules/datalake"
  bucket_name   = "${var.bucket_name}"
  producer_arns = ["${module.import-entity-lambda.lambda_role_arn}"]
}


module "import-orchestration-topic" {
  source         = "./modules/sns"
  publisher_arns = ["${module.fan-out-lambda.lambda_role_arn}"]
}

module "fan-out-lambda" {
  source                         = "./modules/lambda"
  lambda_name                    = "spotifydb-import-fan-out-lambda"
  lambda_file_name               = "fan-out-lambda.zip"
  handler_name                   = "main"
  lambda_timeout_seconds         = "5"
  lambda_runtime                 = "go1.x"
  lambda_memory_size             = "128"
  messages_per_lambda_invocation = "1"
  lambda_environment_variables   = "${local.fan_out_environment_variables}"
  entity_types                   = ["artist"]
  source_bucket_name             = "${aws_s3_bucket.bucket.id}"
  sns_topic_arn                  = "${module.import-orchestration-topic.sns_topic_arn}"
}

module "import-entity-lambda" {
  source                         = "./modules/lambda"
  lambda_name                    = "spotifydb-import-entity-lambda"
  lambda_file_name               = "import-entity-lambda.zip"
  handler_name                   = "main"
  lambda_timeout_seconds         = "10"
  lambda_runtime                 = "go1.x"
  lambda_memory_size             = "128"
  messages_per_lambda_invocation = "10"
  lambda_environment_variables   = "${local.import_environment_variables}"
  entity_types                   = ["album", "artist"]
  source_bucket_name             = "${aws_s3_bucket.bucket.id}"
  sns_topic_arn                  = "${module.import-orchestration-topic.sns_topic_arn}"
}