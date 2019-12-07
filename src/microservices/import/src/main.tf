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

resource "aws_s3_bucket" "bucket" {
  bucket = "spotifydb-import-lambdas"
  versioning {
    enabled = "true" # Used to help determine if a lambda should be updated
  }
}

module "import-orchestration-topic" {
  source = "./modules/sns"
}

module "import-artist-lambda" {
  source               = "./modules/lambda"
  lambda_name          = "spotifydb-artist-import-lambda"
  handler_name         = "com.spotifydb.Handler::handleSqsMessage"
  entity_type          = "artist"
  source_bucket_name   = "${aws_s3_bucket.bucket.id}"
  datalake_bucket_name = "${var.bucket_name}"
  spotify_id           = "${var.spotify_id}"
  spotify_secret       = "${var.spotify_secret}"
  sns_topic_arn        = "${module.import-orchestration-topic.sns_topic_arn}"
}

module "import-album-lambda" {
  source               = "./modules/lambda"
  lambda_name          = "spotifydb-album-import-lambda"
  handler_name         = "com.spotifydb.Handler::handleSqsMessage"
  entity_type          = "album"
  source_bucket_name   = "${aws_s3_bucket.bucket.id}"
  datalake_bucket_name = "${var.bucket_name}"
  spotify_id           = "${var.spotify_id}"
  spotify_secret       = "${var.spotify_secret}"
  sns_topic_arn        = "${module.import-orchestration-topic.sns_topic_arn}"
}