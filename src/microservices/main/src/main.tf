provider "aws" {
  version = "~> 2.0"
  profile = "terraform-user"
  region  = "${var.aws_region}"
}

terraform {
  backend "s3" { # Backend configurations can't have interpolations
    bucket  = "spotifydb-remote-state"
    key     = "microservices/main/terraform.tfstate"
    region  = "us-east-1"
    profile = "terraform-user"
  }
}

data "terraform_remote_state" "global_remote_state" {
  backend = "s3"
  config = {
    bucket  = "spotifydb-remote-state"
    key     = "global/terraform.tfstate"
    region  = "${var.aws_region}"
    profile = "terraform-user"
  }
}

module "sqs" {
  source        = "./modules/sqs"
  sns_topic_arn = "${data.terraform_remote_state.global_remote_state.outputs.datalake_sns_topic_arn}"
}

