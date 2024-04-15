locals {
	owner = "dvagapov"
	bucket_name = "${local.owner}-terraform-remote-state-bucket"
	dynamodb_name = "${local.owner}-terraform-remote-state-lock"
}