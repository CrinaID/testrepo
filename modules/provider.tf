
provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "dm-gen-configuration"
    key    = "/"
    region = "eu-central-1"
  }
}