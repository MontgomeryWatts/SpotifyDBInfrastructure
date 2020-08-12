locals {
  # aws_region looks like us-east-1, MongoDB Atlas wants US_EAST_1
  mongodb_atlas_region = replace(upper(var.aws_region), "-", "_")
}

resource "mongodbatlas_project" "mongodb_atlas_sampler_project" {
  name   = "sampler-for-spotify"
  org_id = var.mongodb_atlas_organization_id
}

resource "mongodbatlas_cluster" "sampler_for_spotify_cluster" {
  name       = "sampler-for-spotify-cluster"
  project_id = mongodbatlas_project.mongodb_atlas_sampler_project.id

  mongo_db_major_version       = "4.0"
  disk_size_gb                 = 2
  auto_scaling_disk_gb_enabled = false

  provider_name               = "AWS"
  provider_instance_size_name = "M10"
  provider_region_name        = local.mongodb_atlas_region
}

resource "mongodbatlas_database_user" "read_only_user" {
  username           = "read_only_user"
  password           = "CHANGEMANUALLYINATLAS"
  project_id         = mongodbatlas_project.mongodb_atlas_sampler_project.id
  auth_database_name = "admin"

  roles {
    role_name     = "read"
    database_name = "spotify_sampler"
  }
}

resource "mongodbatlas_network_container" "sampler_network_container" {
  project_id       = mongodbatlas_project.mongodb_atlas_sampler_project.id
  provider_name    = "AWS"
  atlas_cidr_block = "192.168.0.0/21"
  region_name      = local.mongodb_atlas_region
}

resource "mongodbatlas_network_peering" "mongodbatlas_to_ec2_vpc_peering" {
  accepter_region_name   = local.mongodb_atlas_region
  project_id             = mongodbatlas_project.mongodb_atlas_sampler_project.id
  container_id           = mongodbatlas_network_container.sampler_network_container.container_id
  provider_name          = "AWS"
  vpc_id                 = aws_vpc.ec2_to_mongodbatlas_vpc.id
  aws_account_id         = data.aws_caller_identity.identity.account_id
  route_table_cidr_block = aws_vpc.ec2_to_mongodbatlas_vpc.cidr_block
}

resource "mongodbatlas_project_ip_whitelist" "mongodb_whitelist_container_sg" {
  project_id         = mongodbatlas_project.mongodb_atlas_sampler_project.id
  aws_security_group = aws_security_group.container_sg.id
  depends_on         = [mongodbatlas_network_peering.mongodbatlas_to_ec2_vpc_peering]
}