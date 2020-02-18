provider "mongodbatlas" {
  version     = "~> 0.3.1"
  public_key  = "${var.mongodb_atlas_public_key}"
  private_key = "${var.mongodb_atlas_private_key}"
}

provider "aws" {
  version = "~> 2.0"
  profile = "terraform-user"
  region  = "${var.aws_region}"
}

terraform {
  backend "s3" { # Backend configurations can't have interpolations
    bucket  = "spotifydb-remote-state"
    key     = "microservices/playlist/terraform.tfstate"
    region  = "us-east-1"
    profile = "terraform-user"
  }
}

resource "mongodbatlas_project" "mongodb_atlas_playlist_project" {
  name   = "spotifydb-playlist"
  org_id = "${var.mongodb_atlas_organization_id}"
}

resource "mongodbatlas_cluster" "mongodb_atlas_playlist_cluster" {
  name       = "spotifydb-playlist-cluster"
  project_id = "${mongodbatlas_project.mongodb_atlas_playlist_project.id}"

  mongo_db_major_version       = "4.0"
  disk_size_gb                 = "2"
  auto_scaling_disk_gb_enabled = false # cannot use autoscaling on shared clusters (such as M2)

  provider_name               = "TENANT" # Need to specify tenant to use M2
  backing_provider_name       = "AWS"
  provider_instance_size_name = "M2"
  provider_region_name        = "${var.aws_region}"

  lifecycle { # Can't modify M2 instances in place
    ignore_changes = [
      provider_region_name, # Atlas formats us-east-1 as US-EAST-1 and terraform tries to change it
    ]
  }
}

resource "mongodbatlas_database_user" "name" {
  username      = "lambda-producer"
  password      = "CHANGEMANUALLYINATLAS"
  project_id    = "${mongodbatlas_project.mongodb_atlas_playlist_project.id}"
  database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "music"
  }
}

resource "mongodbatlas_network_container" "spotifydb_playlist_network_container" {
  project_id       = "${mongodbatlas_project.mongodb_atlas_playlist_project.id}"
  provider_name    = "AWS"
  atlas_cidr_block = "192.168.0.0/21"
  region_name      = "${var.aws_region}"

  lifecycle {
    ignore_changes = [
      region_name, # Atlas formats us-east-1 as US-EAST-1 and terraform tries to change it
    ]
  }
}

resource "aws_vpc" "lambda_to_mongodbatlas_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default" # lambdas cannot connect to dedicated vpcs
}

data "aws_caller_identity" "identity" {

}

# MongoDB Atlas VPC requests peering with AWS VPC, AWS VPC accepts the connection

resource "mongodbatlas_network_peering" "mongodbatlas_to_vpc_peering" {
  accepter_region_name   = "${var.aws_region}"
  project_id             = "${mongodbatlas_project.mongodb_atlas_playlist_project.id}"
  container_id           = "${mongodbatlas_network_container.spotifydb_playlist_network_container.container_id}"
  provider_name          = "AWS"
  vpc_id                 = "${aws_vpc.lambda_to_mongodbatlas_vpc.id}"
  aws_account_id         = "${data.aws_caller_identity.identity.account_id}"
  route_table_cidr_block = "${aws_vpc.lambda_to_mongodbatlas_vpc.cidr_block}"
}

resource "aws_vpc_peering_connection_accepter" "vpc_to_mongodbatlas_peering" {
  vpc_peering_connection_id = "${mongodbatlas_network_peering.mongodbatlas_to_vpc_peering.connection_id}"
  auto_accept               = true
}

resource "aws_security_group" "mongodb_lambda_security_group" {
  vpc_id = "${aws_vpc.lambda_to_mongodbatlas_vpc.id}"

}

resource "aws_subnet" "lambda_vpc_subnet" {
  vpc_id     = "${aws_vpc.lambda_to_mongodbatlas_vpc.id}"
  cidr_block = "${aws_vpc.lambda_to_mongodbatlas_vpc.cidr_block}" # This is fine as long as there is only one subnet for the AWS VPC
}

resource "aws_s3_bucket" "bucket" {
  bucket = "spotifydb-playlist-lambdas"
}


# resource "aws_lambda_function" "lambda" {
#   function_name = "spotify-playlist-transform-lambda"
#   handler       = "main"
#   runtime       = "go1.x"
#   role          = "${aws_iam_role.lambda_role.arn}"
# }

resource "aws_iam_role" "transform_lambda_role" {
  name               = "spotify-playlist-transform-lambda-role"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role_policy.json}"
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "role_execution_policy" {
  role   = "${aws_iam_role.transform_lambda_role.id}"
  policy = "${data.aws_iam_policy_document.transform_role_execution_policy_document.json}"
}


data "aws_iam_policy_document" "transform_role_execution_policy_document" {
  version = "2012-10-17"
  statement {
    sid    = "AllowLogs"
    effect = "Allow"
    actions = ["logs:CreateLogGroup",
      "logs:CreateLogStream",
    "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    sid    = "AllowVPCOperations"
    effect = "Allow"
    actions = ["ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
    "ec2:DeleteNetworkInterface"]
    resources = ["*"]
  }
}