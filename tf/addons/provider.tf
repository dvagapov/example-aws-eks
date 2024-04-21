terraform {
  required_version = ">= 1.7.5"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13"
    }
  }

  backend "s3" {
    bucket         = "dvagapov-terraform-remote-state-bucket"
    dynamodb_table = "dvagapov-terraform-remote-state-lock"
    encrypt        = true
  }
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "dvagapov1a"
  }
}
