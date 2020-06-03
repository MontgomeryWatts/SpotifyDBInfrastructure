resource "mongodbatlas_project" "mongodb_atlas_randomizer_project" {
  name   = "spotifydb-randomizer"
  org_id = var.mongodb_atlas_organization_id
}

resource "mongodbatlas_cluster" "mongodb_atlas_playlist_cluster" {
  name       = "spotifydb-playlist-cluster"
  project_id = mongodbatlas_project.mongodb_atlas_randomizer_project.id

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

resource "mongodbatlas_database_user" "producer_user" {
  username           = "lambda_producer"
  password           = "CHANGEMANUALLYINATLAS"
  project_id         = mongodbatlas_project.mongodb_atlas_randomizer_project.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWrite"
    database_name = "music"
  }
}

resource "mongodbatlas_network_container" "spotifydb_playlist_network_container" { # Synonymous with VPC
  project_id       = mongodbatlas_project.mongodb_atlas_randomizer_project.id
  provider_name    = "AWS"
  atlas_cidr_block = "192.168.0.0/21"
  region_name      = var.aws_region

  lifecycle {
    ignore_changes = [
      region_name, # Atlas formats us-east-1 as US_EAST_1 and terraform tries to change it
    ]
  }
}

resource "mongodbatlas_network_peering" "mongodbatlas_to_playlist_vpc_peering" {
  accepter_region_name   = var.aws_region
  project_id             = mongodbatlas_project.mongodb_atlas_randomizer_project.id
  container_id           = mongodbatlas_network_container.spotifydb_playlist_network_container.container_id
  provider_name          = "AWS"
  vpc_id                 = aws_vpc.playlist_lambda_to_mongodbatlas_vpc.id
  aws_account_id         = data.aws_caller_identity.identity.account_id
  route_table_cidr_block = aws_vpc.playlist_lambda_to_mongodbatlas_vpc.cidr_block
}

resource "mongodbatlas_project_ip_whitelist" "mongodb_whitelist" {
  project_id         = mongodbatlas_project.mongodb_atlas_randomizer_project.id
  aws_security_group = aws_security_group.mongodb_playlist_lambda_security_group.id
}