terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "3.25.0"
      }
    }

    backend "s3" {
      key = "test/terraform.tfstate"
      region = var.region
    }  
}