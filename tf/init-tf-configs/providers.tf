terraform {
  required_version = ">= 1.7.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.45"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}