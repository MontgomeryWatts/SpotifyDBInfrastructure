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
  source                   = "./modules/sns"
  #fan_out_lambda_role_arns = ["${module.import-artist-albums-lambda.lambda_role_arn}"]
}