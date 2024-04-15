terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    region  = "eu-central-1"
    bucket  = "dvagapov-terraform-remote-state-bucket"
    key     = "terraform.tfstate"
    profile = ""
    encrypt = "true"

    dynamodb_table = "dvagapov-terraform-remote-state-lock"
  }
}
