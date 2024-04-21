terraform {
  required_version = ">= 1.7.5"

  required_providers {
    datadog = {
      source  = "datadog/datadog"
      version = ">= 3.19.1"
    }
  }

  backend "s3" {
    bucket         = "dvagapov-terraform-remote-state-bucket"
    dynamodb_table = "dvagapov-terraform-remote-state-lock"
    encrypt        = true
  }
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = var.datadog_api_url
}
