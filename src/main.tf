provider "aws" {
  version = "~> 2.39.0"
  profile = "terraform-user"
  region  = var.aws_region
}

provider "mongodbatlas" {
  version     = "~> 0.4.0"
  public_key  = var.mongodb_atlas_public_key
  private_key = var.mongodb_atlas_private_key
}

terraform {
  backend "s3" { # Backend configurations can't have interpolations
    bucket  = "spotifydb-remote-state"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    profile = "terraform-user"
  }
}

data "aws_caller_identity" "identity" {

}
