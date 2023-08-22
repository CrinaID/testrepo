provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "vpc_dev_test" {
  cidr_block = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support = true
  tags      = {
    Name    = "${var.env_name}-vpc"
  }
}

data "aws_availability_zones" "available" {}
resource "aws_subnet" "public_subnet_one" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.public_subnet_one_cidr
  vpc_id = aws_vpc.vpc_dev_test.id
  tags = {
    "Name" = "PublicSubnetOne-${var.env_name}"
  }
}
resource "aws_subnet" "public_subnet_two" {
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = var.public_subnet_two_cidr
  vpc_id = aws_vpc.vpc_dev_test.id
  tags = {
    "Name" = "PublicSubnetOne-${var.env_name}"
  }
}
resource "aws_subnet" "private_subnet_one" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.private_subnet_one_cidr
  vpc_id = aws_vpc.vpc_dev_test.id
  tags = {
    "Name" = "PrivateSubnetOne-${var.env_name}"
  }
}
resource "aws_subnet" "private_subnet_two" {
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = var.private_subnet_two_cidr
  vpc_id = aws_vpc.vpc_dev_test.id
  tags = {
    "Name" = "PrivateSubnetTwo-${var.env_name}"
  }
}

//Create an Internet Gateway 
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc_dev_test.id
  tags = {
    "Name" = "InternetGateway-${var.env_name}"
  }
}
//create route table for the Internet Gateway
resource "aws_route_table" "internet_gateway_rt" {
  vpc_id = aws_vpc.vpc_dev_test.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    "Name" = "InternetGatewayRT-${var.env_name}"
  }
}
//associate the IGW to the first public subnet
resource "aws_route_table_association" "nat_gateway_one_rt" {
  subnet_id = aws_subnet.public_subnet_one.id
  route_table_id = aws_route_table.internet_gateway_rt.id

}
//Create Elastic IP for the NAT Gateway
resource "aws_eip" "Nat-Gateway-EIP" {
  depends_on = [
    aws_route_table_association. nat_gateway_one_rt
  ]
  vpc = true
  tags = {
    "Name" = "ElasticIP-${var.env_name}"
  }
}

resource "aws_nat_gateway" "nat_gateway_one" {
  depends_on = [
    aws_eip.Nat-Gateway-EIP
  ]
 
  # Allocating the Elastic IP to the NAT Gateway!
  allocation_id = aws_eip.Nat-Gateway-EIP.id
  
  # Associating it in the Public Subnet!
  subnet_id = aws_subnet.public_subnet_one.id
  tags = {
    Name = "NatGateway-${var.env_name}"
  }
}