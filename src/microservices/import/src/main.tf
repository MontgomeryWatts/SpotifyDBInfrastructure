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
}

module "import-artist-lambda" {
  source               = "./modules/lambda"
  source_bucket_name   = "${aws_s3_bucket.bucket.id}"
  datalake_bucket_name = "${var.bucket_name}"
  spotify_id           = "${var.spotify_id}"
  spotify_secret       = "${var.spotify_secret}"
  lambda_name          = "spotifydb-artist-import-lambda"
  handler_name         = "com.spotifydb.Handler::importArtist"
}

module "import-album-lambda" {
  source               = "./modules/lambda"
  source_bucket_name   = "${aws_s3_bucket.bucket.id}"
  datalake_bucket_name = "${var.bucket_name}"
  spotify_id           = "${var.spotify_id}"
  spotify_secret       = "${var.spotify_secret}"
  lambda_name          = "spotifydb-album-import-lambda"
  handler_name         = "com.spotifydb.Handler::importAlbum"
}