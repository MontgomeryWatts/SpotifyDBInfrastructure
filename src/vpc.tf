locals {
  aws_vpc_tags = {
    "Name" = "EC2 MongoDB Atlas VPC"
  }
}

resource "aws_vpc" "ec2_to_mongodbatlas_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags                 = local.aws_vpc_tags
}

resource "aws_vpc_peering_connection_accepter" "ec2_vpc_to_mongodbatlas_peering" {
  vpc_peering_connection_id = mongodbatlas_network_peering.mongodbatlas_to_ec2_vpc_peering.connection_id
  auto_accept               = true
  tags                      = local.aws_vpc_tags
}

resource "aws_internet_gateway" "load_balancer_igw" {
  vpc_id = aws_vpc.ec2_to_mongodbatlas_vpc.id
}

resource "aws_security_group" "container_sg" {
  name   = "Container SG"
  vpc_id = aws_vpc.ec2_to_mongodbatlas_vpc.id
  tags   = local.aws_vpc_tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "load_balancer_sg" {
  name   = "Load Balancer SG"
  vpc_id = aws_vpc.ec2_to_mongodbatlas_vpc.id
  tags   = local.aws_vpc_tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "container_retrieve_image_outbound_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.container_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "load_balancer_http_web_traffic_inbound_rule" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.load_balancer_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "load_balancer_https_web_traffic_inbound_rule" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.load_balancer_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "load_balancer_http_web_traffic_outbound_rule" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.load_balancer_sg.id
  source_security_group_id = aws_security_group.container_sg.id
}

resource "aws_security_group_rule" "container_http_web_traffic_inbound_rule" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.container_sg.id
  source_security_group_id = aws_security_group.load_balancer_sg.id
}

resource "aws_security_group_rule" "mongodb_inbound_rule" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.container_sg.id
  cidr_blocks       = [mongodbatlas_network_container.sampler_network_container.atlas_cidr_block]
}

resource "aws_security_group_rule" "mongodb_outbound_rule" {
  type              = "egress"
  from_port         = 27015
  to_port           = 27017
  protocol          = "tcp"
  security_group_id = aws_security_group.container_sg.id
  cidr_blocks       = [mongodbatlas_network_container.sampler_network_container.atlas_cidr_block]
}

resource "aws_subnet" "container_subnet" {
  count             = length(data.aws_availability_zones.available.names)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.ec2_to_mongodbatlas_vpc.id
  cidr_block        = "10.0.${0 + count.index}.0/24"
}

resource "aws_route_table_association" "container_subnet_association" {
  count          = length(aws_subnet.container_subnet[*])
  subnet_id      = aws_subnet.container_subnet[count.index].id
  route_table_id = aws_vpc.ec2_to_mongodbatlas_vpc.main_route_table_id
}

resource "aws_subnet" "load_balancer_subnet" {
  count             = length(data.aws_availability_zones.available.names)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.ec2_to_mongodbatlas_vpc.id
  cidr_block        = "10.0.${128 + count.index}.0/24"
}

resource "aws_route_table_association" "load_balancer_subnet_association" {
  count          = length(aws_subnet.load_balancer_subnet[*])
  subnet_id      = aws_subnet.load_balancer_subnet[count.index].id
  route_table_id = aws_vpc.ec2_to_mongodbatlas_vpc.main_route_table_id
}

resource "aws_route" "route_to_mongodbatlas" {
  route_table_id            = aws_vpc.ec2_to_mongodbatlas_vpc.main_route_table_id
  destination_cidr_block    = mongodbatlas_network_container.sampler_network_container.atlas_cidr_block
  vpc_peering_connection_id = mongodbatlas_network_peering.mongodbatlas_to_ec2_vpc_peering.connection_id
}

resource "aws_route" "route_to_load_balancer_igw" {
  route_table_id         = aws_vpc.ec2_to_mongodbatlas_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.load_balancer_igw.id
}

