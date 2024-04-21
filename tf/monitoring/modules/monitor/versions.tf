
terraform {
  required_version = ">= 1.7.5"
  required_providers {
    datadog = {
      source  = "datadog/datadog"
      version = ">= 3.19.1"
    }
  }
}