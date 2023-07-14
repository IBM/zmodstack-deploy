resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  instance_tenancy     = var.tenancy

  tags = {
    Name = "${var.network_tag_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "control_plane_node" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "control_plane_node1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.control_plane_node_subnet_cidr1
  availability_zone       = var.availability_zone1
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.control_plane_node]

  tags = {
    "Name" : join("-", [var.network_tag_prefix, "public-subnet", var.availability_zone1])
  }
}
resource "aws_subnet" "control_plane_node2" {
  count                   = var.az == "multi_zone" ? 1 : 0
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.control_plane_node_subnet_cidr2
  availability_zone       = var.availability_zone2
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.control_plane_node]

  tags = {
    "Name" : join("-", [var.network_tag_prefix, "public-subnet", var.availability_zone2])
  }
}
resource "aws_subnet" "control_plane_node3" {
  count                   = var.az == "multi_zone" ? 1 : 0
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.control_plane_node_subnet_cidr3
  availability_zone       = var.availability_zone3
  map_public_ip_on_launch = true
  depends_on              = [aws_internet_gateway.control_plane_node]

  tags = {
    "Name" : join("-", [var.network_tag_prefix, "public-subnet", var.availability_zone3])
  }
}

resource "aws_route_table" "control_plane_node" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.control_plane_node.id
  }
}

resource "aws_route_table_association" "control_plane_node1" {
  subnet_id      = aws_subnet.control_plane_node1.id
  route_table_id = aws_route_table.control_plane_node.id
}
resource "aws_route_table_association" "control_plane_node2" {
  count          = var.az == "multi_zone" ? 1 : 0
  subnet_id      = aws_subnet.control_plane_node2[0].id
  route_table_id = aws_route_table.control_plane_node.id
}
resource "aws_route_table_association" "control_plane_node3" {
  count          = var.az == "multi_zone" ? 1 : 0
  subnet_id      = aws_subnet.control_plane_node3[0].id
  route_table_id = aws_route_table.control_plane_node.id
}

resource "aws_eip" "eip1" {
  vpc = true

  depends_on = [
    aws_vpc.vpc,
  ]
}
resource "aws_eip" "eip2" {
  count = var.az == "multi_zone" ? 1 : 0
  vpc   = true

  depends_on = [
    aws_vpc.vpc,
  ]
}
resource "aws_eip" "eip3" {
  count = var.az == "multi_zone" ? 1 : 0
  vpc   = true

  depends_on = [
    aws_vpc.vpc,
  ]
}
resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.eip1.id
  subnet_id     = aws_subnet.control_plane_node1.id
}
resource "aws_nat_gateway" "nat2" {
  count         = var.az == "multi_zone" ? 1 : 0
  allocation_id = aws_eip.eip2[0].id
  subnet_id     = aws_subnet.control_plane_node2[0].id
}
resource "aws_nat_gateway" "nat3" {
  count         = var.az == "multi_zone" ? 1 : 0
  allocation_id = aws_eip.eip3[0].id
  subnet_id     = aws_subnet.control_plane_node3[0].id
}
resource "aws_subnet" "computenode1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.computenode_subnet_cidr1
  availability_zone = var.availability_zone1
  depends_on        = [aws_nat_gateway.nat1]

  tags = {
    "Name" : join("-", [var.network_tag_prefix, "private-subnet", var.availability_zone1])
  }
}
resource "aws_subnet" "computenode2" {
  count             = var.az == "multi_zone" ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.computenode_subnet_cidr2
  availability_zone = var.availability_zone2
  depends_on        = [aws_nat_gateway.nat2]

  tags = {
    "Name" : join("-", [var.network_tag_prefix, "private-subnet", var.availability_zone2])
  }
}
resource "aws_subnet" "computenode3" {
  count             = var.az == "multi_zone" ? 1 : 0
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.computenode_subnet_cidr3
  availability_zone = var.availability_zone3
  depends_on        = [aws_nat_gateway.nat3]

  tags = {
    "Name" : join("-", [var.network_tag_prefix, "private-subnet", var.availability_zone3])
  }
}
resource "aws_route_table" "computenode1" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat1.id
  }
}
resource "aws_route_table" "computenode2" {
  count  = var.az == "multi_zone" ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat2[0].id
  }
}
resource "aws_route_table" "computenode3" {
  count  = var.az == "multi_zone" ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat3[0].id
  }
}
resource "aws_route_table_association" "privateroute1" {
  subnet_id      = aws_subnet.computenode1.id
  route_table_id = aws_route_table.computenode1.id
}
resource "aws_route_table_association" "privateroute2" {
  count          = var.az == "multi_zone" ? 1 : 0
  subnet_id      = aws_subnet.computenode2[0].id
  route_table_id = aws_route_table.computenode2[0].id
}
resource "aws_route_table_association" "privateroute3" {
  count          = var.az == "multi_zone" ? 1 : 0
  subnet_id      = aws_subnet.computenode3[0].id
  route_table_id = aws_route_table.computenode3[0].id
}
/*
This security group allows intra-node communication on all ports with all
protocols.
*/
resource "aws_security_group" "openshift-vpc" {
  name        = "${var.network_tag_prefix}-openshift-vpc"
  description = "Default security group that allows all instances in the VPC to talk to each other over any port and protocol."
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true
  }
}