
/*provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "dm-gen-configuration"
    key    = "/"
    region = "eu-central-1"
  }
}*/

resource "aws_vpc" "vpc_dm_eks" {
  cidr_block = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support = true
  tags      = {
    Name    = "${var.project_code}-${var.env_name}-vpc"
  }
}

data "aws_availability_zones" "available" {}

// What if the number of subnets differs from the number of availability zones?
// Code needs to be refactored/improved for private and public subnet resources!
resource "aws_subnet" "public_subnets" {
  count = "${length(var.public_subnets)}"

  cidr_block = var.public_subnets[count.index]
  availability_zone= "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id   = aws_vpc.vpc_dm_eks.id
  tags = {
    Name = "${var.project_code}-${var.env_name}-publicsub-${1+count.index}"
  }
}

resource "aws_subnet" "private_subnets" {
  
  count = "${length(var.private_subnets)}"
  cidr_block = var.private_subnets[count.index]
  availability_zone= "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id   = aws_vpc.vpc_dm_eks.id
  tags = {
    Name = "${var.project_code}-${var.env_name}-privatesub-${1+count.index}"
  }
}

//Create an Internet Gateway 
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc_dm_eks.id
  tags = {
    "Name" = "${var.project_code}-${var.env_name}-igw"
  }
}
//create route table for the Internet Gateway
resource "aws_route_table" "internet_gateway_rt" {
  vpc_id = aws_vpc.vpc_dm_eks.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    "Name" = "${var.project_code}-${var.env_name}-routetbl"
  }
  
}
//associate the IGW to the first public subnet
resource "aws_route_table_association" "nat_gateway_one_rt" {
  subnet_id = aws_subnet.public_subnets[0].id
  route_table_id = aws_route_table.internet_gateway_rt.id

}
//Create Elastic IP for the NAT Gateway
resource "aws_eip" "Nat-Gateway-EIP" {
  depends_on = [
    aws_route_table_association. nat_gateway_one_rt
  ]
  vpc = true
  tags = {
    "Name" = "${var.project_code}-${var.env_name}-ElasticIP"
  
  }
}

resource "aws_nat_gateway" "nat_gateway_one" {
  depends_on = [
    aws_eip.Nat-Gateway-EIP,
    aws_internet_gateway.internet_gateway
  ]
 
  # Allocating the Elastic IP to the NAT Gateway!
  allocation_id = aws_eip.Nat-Gateway-EIP.id
  
  # Associating it in the Public Subnet!
  subnet_id = aws_subnet.public_subnets[0].id
  tags = {
    Name = "${var.project_code}-${var.env_name}-NAT"
  
  }
}

