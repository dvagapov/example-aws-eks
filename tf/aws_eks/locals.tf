locals {
  name            = "ex-${replace(basename(path.cwd), "_", "-")}"
	cluster_version = "1.29"
  region          = "eu-west-1"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    k8s_cluster_name  = var.cluster_name
    GithubRepo 				= "example-aws-eks"
    GithubOrg  				= "dvagapov"
  }
	
  ebs_csi_service_account_namespace = "kube-system"
  ebs_csi_service_account_name = "ebs-csi-controller-sa"
}