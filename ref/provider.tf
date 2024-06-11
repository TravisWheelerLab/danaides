terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.50"
      }
    }

    required_version = ">= 1.8.0"
}

provider "aws" {
  profile = "dev"
  region = "us-west-2"
}
