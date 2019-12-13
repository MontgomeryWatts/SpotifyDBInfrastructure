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

module "import-orchestration-topic" {
  source = "./modules/sns"
}

module "import-artist-lambda" {
  source                       = "./modules/lambda"
  lambda_name                  = "spotifydb-artist-import-lambda"
  lambda_file_name             = "spotifydb-artist-import-lambda.jar"
  handler_name                 = "com.spotifydb.Handler::handleSqsMessage"
  lambda_timeout_seconds       = "5"
  lambda_runtime               = "java8"
  lambda_memory_size           = "320"
  lambda_environment_variables = "${local.import_environment_variables}"
  entity_type                  = "artist"
  source_bucket_name           = "${aws_s3_bucket.bucket.id}"
  sns_topic_arn                = "${module.import-orchestration-topic.sns_topic_arn}"
}

module "import-album-lambda" {
  source                       = "./modules/lambda"
  lambda_name                  = "spotifydb-album-import-lambda"
  lambda_file_name             = "spotifydb-album-import-lambda.jar"
  handler_name                 = "com.spotifydb.Handler::handleSqsMessage"
  lambda_timeout_seconds       = "5"
  lambda_runtime               = "java8"
  lambda_memory_size           = "320"
  lambda_environment_variables = "${local.import_environment_variables}"
  entity_type                  = "album"
  source_bucket_name           = "${aws_s3_bucket.bucket.id}"
  sns_topic_arn                = "${module.import-orchestration-topic.sns_topic_arn}"
}

module "import-artist-albums-lambda" {
  source                       = "./modules/lambda"
  lambda_name                  = "spotifydb-artist-album-fanout-lambda"
  lambda_file_name             = "get-artist-albums.zip"
  handler_name                 = "main"
  lambda_timeout_seconds       = "10"
  lambda_runtime               = "go1.x"
  lambda_memory_size           = "128"
  lambda_environment_variables = "${local.fan_out_environment_variables}"
  entity_type                  = "artist"
  source_bucket_name           = "${aws_s3_bucket.bucket.id}"
  sns_topic_arn                = "${module.import-orchestration-topic.sns_topic_arn}"
}