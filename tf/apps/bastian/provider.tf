terraform {
  required_version = ">= 1.7.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.45"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0"
    }
  }

  backend "s3" {
    bucket         = "dvagapov-terraform-remote-state-bucket"
    dynamodb_table = "dvagapov-terraform-remote-state-lock"
    encrypt        = true
  }
}

data "aws_eks_cluster" "default" {
  name = var.cluster_name
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", var.cluster_name]
  }
}