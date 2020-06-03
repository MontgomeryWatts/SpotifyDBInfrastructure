resource "aws_vpc" "playlist_lambda_to_mongodbatlas_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default" # lambdas cannot connect to dedicated vpcs
}

resource "aws_vpc_peering_connection_accepter" "playlist_vpc_to_mongodbatlas_peering" {
  vpc_peering_connection_id = mongodbatlas_network_peering.mongodbatlas_to_playlist_vpc_peering.connection_id
  auto_accept               = true
}

resource "aws_security_group" "mongodb_playlist_lambda_security_group" {
  vpc_id = aws_vpc.playlist_lambda_to_mongodbatlas_vpc.id
}

resource "aws_security_group_rule" "mongodb_inbound_rule" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.mongodb_playlist_lambda_security_group.id
  cidr_blocks       = [mongodbatlas_network_container.spotifydb_playlist_network_container.atlas_cidr_block]
}

resource "aws_security_group_rule" "s3_security_group_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.mongodb_playlist_lambda_security_group.id
  prefix_list_ids   = [aws_vpc_endpoint.s3_playlist_lambda_vpc_endpoint.prefix_list_id]
}

resource "aws_security_group_rule" "mongodb_outbound_rule" {
  type              = "egress"
  from_port         = 27015
  to_port           = 27017
  protocol          = "tcp"
  security_group_id = aws_security_group.mongodb_playlist_lambda_security_group.id
  cidr_blocks       = [mongodbatlas_network_container.spotifydb_playlist_network_container.atlas_cidr_block]
}

resource "aws_subnet" "playlist_lambda_vpc_subnet" {
  vpc_id     = aws_vpc.playlist_lambda_to_mongodbatlas_vpc.id
  cidr_block = aws_vpc.playlist_lambda_to_mongodbatlas_vpc.cidr_block
}

resource "aws_route_table_association" "playlist_lambda_subnet_association" {
  subnet_id      = aws_subnet.playlist_lambda_vpc_subnet.id
  route_table_id = aws_vpc.playlist_lambda_to_mongodbatlas_vpc.main_route_table_id
}


resource "aws_vpc_endpoint" "s3_playlist_lambda_vpc_endpoint" { # Endpoint to allow Lambdas to access S3
  vpc_id            = aws_vpc.playlist_lambda_to_mongodbatlas_vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
}

resource "aws_vpc_endpoint_route_table_association" "route_s3_endpoint_to_playlist_lambda_subnet" { # Connect endpoint and route table
  route_table_id  = aws_vpc.playlist_lambda_to_mongodbatlas_vpc.main_route_table_id
  vpc_endpoint_id = aws_vpc_endpoint.s3_playlist_lambda_vpc_endpoint.id
}

resource "aws_route" "route_to_mongodbatlas" {
  route_table_id            = aws_vpc.playlist_lambda_to_mongodbatlas_vpc.main_route_table_id
  destination_cidr_block    = mongodbatlas_network_container.spotifydb_playlist_network_container.atlas_cidr_block
  vpc_peering_connection_id = mongodbatlas_network_peering.mongodbatlas_to_playlist_vpc_peering.connection_id
}
