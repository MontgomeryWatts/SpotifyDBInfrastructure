resource "aws_vpc" "ec2_to_mongodbatlas_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
}

resource "aws_vpc_peering_connection_accepter" "ec2_vpc_to_mongodbatlas_peering" {
  vpc_peering_connection_id = mongodbatlas_network_peering.mongodbatlas_to_ec2_vpc_peering.connection_id
  auto_accept               = true
}

resource "aws_security_group" "ec2_to_mongodbatlas_sg" {
  vpc_id = aws_vpc.ec2_to_mongodbatlas_vpc.id
}

resource "aws_security_group_rule" "mongodb_inbound_rule" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2_to_mongodbatlas_sg.id
  cidr_blocks       = [mongodbatlas_network_container.sampler_network_container.atlas_cidr_block]
}

resource "aws_security_group_rule" "mongodb_outbound_rule" {
  type              = "egress"
  from_port         = 27015
  to_port           = 27017
  protocol          = "tcp"
  security_group_id = aws_security_group.ec2_to_mongodbatlas_sg.id
  cidr_blocks       = [mongodbatlas_network_container.sampler_network_container.atlas_cidr_block]
}

resource "aws_subnet" "playlist_lambda_vpc_subnet" {
  vpc_id     = aws_vpc.ec2_to_mongodbatlas_vpc.id
  cidr_block = aws_vpc.ec2_to_mongodbatlas_vpc.cidr_block
}

resource "aws_route_table_association" "playlist_lambda_subnet_association" {
  subnet_id      = aws_subnet.playlist_lambda_vpc_subnet.id
  route_table_id = aws_vpc.ec2_to_mongodbatlas_vpc.main_route_table_id
}

resource "aws_route" "route_to_mongodbatlas" {
  route_table_id            = aws_vpc.ec2_to_mongodbatlas_vpc.main_route_table_id
  destination_cidr_block    = mongodbatlas_network_container.sampler_network_container.atlas_cidr_block
  vpc_peering_connection_id = mongodbatlas_network_peering.mongodbatlas_to_ec2_vpc_peering.connection_id
}
