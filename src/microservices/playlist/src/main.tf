provider "mongodbatlas" {
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
}
