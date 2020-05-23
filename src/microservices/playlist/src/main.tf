provider "mongodbatlas" {
  version     = "~> 0.4.0"
  public_key  = var.mongodb_atlas_public_key
  private_key = var.mongodb_atlas_private_key
}

provider "aws" {
  version = "~> 2.0"
  profile = "terraform-user"
  region  = var.aws_region
}

terraform {
  backend "s3" { # Backend configurations can't have interpolations
    bucket  = "spotifydb-remote-state"
    key     = "microservices/playlist/terraform.tfstate"
    region  = "us-east-1"
    profile = "terraform-user"
  }
}

data "terraform_remote_state" "import_remote_state" {
  backend = "s3"
  config = {
    bucket  = "spotifydb-remote-state"
    key     = "microservices/import/terraform.tfstate"
    region  = var.aws_region
    profile = "terraform-user"
  }
}

#################
# MongoDB Block #
#################

resource "mongodbatlas_project" "mongodb_atlas_playlist_project" {
  name   = "spotifydb-playlist"
  org_id = var.mongodb_atlas_organization_id
}

resource "mongodbatlas_cluster" "mongodb_atlas_playlist_cluster" {
  name       = "spotifydb-playlist-cluster"
  project_id = mongodbatlas_project.mongodb_atlas_playlist_project.id

  mongo_db_major_version       = "4.0"
  disk_size_gb                 = 2
  auto_scaling_disk_gb_enabled = false

  provider_name               = "AWS"
  provider_instance_size_name = "M10"
  provider_region_name        = var.aws_region

  lifecycle { # Can't modify M2 instances in place
    ignore_changes = [
      provider_region_name, # Atlas formats us-east-1 as US_EAST_1 and terraform tries to change it
    ]
  }
}

resource "mongodbatlas_database_user" "name" {
  username           = "lambda-producer"
  password           = "CHANGEMANUALLYINATLAS"
  project_id         = mongodbatlas_project.mongodb_atlas_playlist_project.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "music"
  }
}

####################
# Networking Block #
####################

resource "mongodbatlas_network_container" "spotifydb_playlist_network_container" { # Synonymous with VPC
  project_id       = mongodbatlas_project.mongodb_atlas_playlist_project.id
  provider_name    = "AWS"
  atlas_cidr_block = "192.168.0.0/21"
  region_name      = var.aws_region

  lifecycle {
    ignore_changes = [
      region_name, # Atlas formats us-east-1 as US_EAST_1 and terraform tries to change it
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
  accepter_region_name   = var.aws_region
  project_id             = mongodbatlas_project.mongodb_atlas_playlist_project.id
  container_id           = mongodbatlas_network_container.spotifydb_playlist_network_container.container_id
  provider_name          = "AWS"
  vpc_id                 = aws_vpc.lambda_to_mongodbatlas_vpc.id
  aws_account_id         = data.aws_caller_identity.identity.account_id
  route_table_cidr_block = aws_vpc.lambda_to_mongodbatlas_vpc.cidr_block
}

resource "aws_vpc_peering_connection_accepter" "vpc_to_mongodbatlas_peering" {
  vpc_peering_connection_id = mongodbatlas_network_peering.mongodbatlas_to_vpc_peering.connection_id
  auto_accept               = true
}

resource "aws_security_group" "mongodb_lambda_security_group" {
  vpc_id = aws_vpc.lambda_to_mongodbatlas_vpc.id
}

resource "aws_security_group_rule" "mongodb_inbound_rule" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.mongodb_lambda_security_group.id
  cidr_blocks       = [mongodbatlas_network_container.spotifydb_playlist_network_container.atlas_cidr_block]
}

resource "aws_security_group_rule" "s3_security_group_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.mongodb_lambda_security_group.id
  prefix_list_ids   = [aws_vpc_endpoint.s3_vpc_endpoint.prefix_list_id]
}

resource "aws_security_group_rule" "mongodb_outbound_rule" {
  type              = "egress"
  from_port         = 27015
  to_port           = 27017
  protocol          = "tcp"
  security_group_id = aws_security_group.mongodb_lambda_security_group.id
  cidr_blocks       = [mongodbatlas_network_container.spotifydb_playlist_network_container.atlas_cidr_block]
}


resource "mongodbatlas_project_ip_whitelist" "mongodb_whitelist" { # Whitelist the above security group in MongoDB Atlas
  project_id         = mongodbatlas_project.mongodb_atlas_playlist_project.id
  aws_security_group = aws_security_group.mongodb_lambda_security_group.id
}

resource "aws_subnet" "lambda_vpc_subnet" {
  vpc_id     = aws_vpc.lambda_to_mongodbatlas_vpc.id
  cidr_block = aws_vpc.lambda_to_mongodbatlas_vpc.cidr_block # This is fine as long as there is only one subnet for the AWS VPC
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.lambda_vpc_subnet.id
  route_table_id = aws_vpc.lambda_to_mongodbatlas_vpc.main_route_table_id
}


resource "aws_vpc_endpoint" "s3_vpc_endpoint" { # Endpoint to allow Lambdas to access S3
  vpc_id            = aws_vpc.lambda_to_mongodbatlas_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
}

resource "aws_vpc_endpoint_route_table_association" "route_s3_endpoint_to_subnets" { # Connect endpoint and route table
  route_table_id  = aws_vpc.lambda_to_mongodbatlas_vpc.main_route_table_id
  vpc_endpoint_id = aws_vpc_endpoint.s3_vpc_endpoint.id
}

resource "aws_route" "route_to_mongo" {
  route_table_id            = aws_vpc.lambda_to_mongodbatlas_vpc.main_route_table_id
  destination_cidr_block    = mongodbatlas_network_container.spotifydb_playlist_network_container.atlas_cidr_block
  vpc_peering_connection_id = mongodbatlas_network_peering.mongodbatlas_to_vpc_peering.connection_id
}


#############
# AWS Block #
#############

resource "aws_s3_bucket" "bucket" {
  bucket = "spotifydb-playlist-lambdas"
}


resource "aws_lambda_function" "lambda" {
  function_name = "spotify-playlist-transform-lambda"
  handler       = "main"
  runtime       = "go1.x"
  role          = aws_iam_role.transform_lambda_role.arn
  s3_bucket     = aws_s3_bucket.bucket.id
  timeout       = 10
  s3_key        = "playlist-transform-lambda.zip"

  vpc_config {
    subnet_ids         = [aws_subnet.lambda_vpc_subnet.id]
    security_group_ids = [aws_security_group.mongodb_lambda_security_group.id]
  }

  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
      MONGODB_URI = var.mongodb_uri
    }
  }
}

resource "aws_iam_role" "transform_lambda_role" {
  name               = "spotify-playlist-transform-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
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
  role   = aws_iam_role.transform_lambda_role.id
  policy = data.aws_iam_policy_document.transform_role_execution_policy_document.json
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
  statement {
    sid    = "AllowSQSOperations"
    effect = "Allow"
    actions = ["sqs:ReceiveMessage",
      "sqs:DeleteMessage",
    "sqs:GetQueueAttributes"]
    resources = [aws_sqs_queue.spotifydb_playlist_sqs.arn]
  }
}

resource "aws_sqs_queue" "spotifydb_playlist_sqs" {
  name = "SpotifyDB-Playlist-Transform-Queue"
}

resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.spotifydb_playlist_sqs.id
  policy    = data.aws_iam_policy_document.queue_policy_document.json
}

data "aws_iam_policy_document" "queue_policy_document" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.spotifydb_playlist_sqs.arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [data.terraform_remote_state.import_remote_state.outputs.import_sns_topic_arn]
    }
  }
}

resource "aws_sns_topic_subscription" "subscribe_lambda_to_sns" {
  topic_arn            = data.terraform_remote_state.import_remote_state.outputs.import_sns_topic_arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.spotifydb_playlist_sqs.arn
  raw_message_delivery = true
}

resource "aws_lambda_event_source_mapping" "trigger_lambda_from_sqs" {
  event_source_arn = aws_sqs_queue.spotifydb_playlist_sqs.arn
  function_name    = aws_lambda_function.lambda.arn
  batch_size       = 5
}