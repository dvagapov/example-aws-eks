terraform {
  required_version = ">= 1.7.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.45"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.16.1"
    }
  }

  backend "s3" {
    bucket         = "dvagapov-terraform-remote-state-bucket"
    dynamodb_table = "dvagapov-terraform-remote-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

