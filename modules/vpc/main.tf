resource "aws_vpc" "vpc" {
    cidr_block = var.cidr_vpc
    enable_dns_hostnames = "true"
    enable_dns_support = "true"

}

/*resource "aws_subnet" "public" {
    cidr_block = cidrsubnet("${var.cidr_cidr}, 8, 1")
    vpc_id = aws_vpc.vpc.id
     
}

resource "aws_subnet" "private"{
    cidr_block = cidrsubnet("${var.cidr_cidr}, 8, 2")
    vpc_id = aws_vpc.vpc.id
}*/
//parametrize this code
provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support = true
  tags      = {
    Name    = "${var.env_name} -vpc"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "private_subnet_one" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.subnet_one_cidr
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "PrivateSubnetOne-${var.env_name}"
  }
}
resource "aws_subnet" "private_subnet_two" {
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = var.subnet_two_cidr
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "PrivateSubnetTwo-${var.env_name}"
  }
}
resource "aws_subnet" "nat_gateway_one" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.nat_gateway_one_cidr
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "SubnetOneNAT-${var.env_name}"
  }
}
/*resource "aws_subnet" "nat_gateway_two" {
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = var.nat_gateway_two_cidr
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "SubnetTwoNAT-${var.env_name}"
  }
}*/
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "InternetGateway-${var.env_name}"
  }
}

resource "aws_route_table" "internet_gateway_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
    tags = {
    "Name" = "InternetGatewayRT-${var.env_name}"
  }
}

resource "aws_route_table_association" "nat_gateway_one_rt" {
  subnet_id = aws_subnet.nat_gateway_one
  route_table_id = aws_route_table.internet_gateway_rt.id
}

/*resource "aws_route_table_association" "nat_gateway_two_rt" {
  subnet_id = aws_subnet.nat_gateway_two
  route_table_id = aws_route_table.internet_gateway_rt.id
}*/
