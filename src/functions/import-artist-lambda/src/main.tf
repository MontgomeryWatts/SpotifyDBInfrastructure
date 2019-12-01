provider "aws" {
  version = "~> 2.0"
  profile = "terraform-user"
  region  = "${var.aws_region}"
}

terraform {
  backend "s3" { # Backend configurations can't have interpolations
    bucket  = "spotifydb-remote-state"
    key     = "functions/import-artist-lambda/terraform.tfstate"
    region  = "us-east-1"
    profile = "terraform-user"
  }
}

module "lambda" {
  source        = "./modules/lambda"
  client_id     = "${var.client_id}"
  client_secret = "${var.client_secret}"
}
