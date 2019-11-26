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

module "s3_datalake" {
  source      = "./modules/s3"
  bucket_name = "spotifydb-datalake"
}
