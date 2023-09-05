provider "aws" {
  region = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket = "dm-gen-configuration"
    key    = "/"
    region = "eu-west-1"
  }
}