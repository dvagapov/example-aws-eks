# You cannot create a new backend by simply defining this and then
# immediately proceeding to "terraform apply". The S3 backend must
# be bootstrapped according to the simple yet essential procedure in
# https://github.com/cloudposse/terraform-aws-tfstate-backend#usage
module "terraform_state_backend" {
  source = "cloudposse/tfstate-backend/aws"
  # Cloud Posse recommends pinning every module to a specific version
  version     = "1.4.1"

  s3_bucket_name = local.bucket_name
  dynamodb_table_name = local.dynamodb_name
  // Usually an abbreviation of your organization name
  namespace  = "dv"
  // Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release'
  stage      = "dev"
  name       = "terraform"
  attributes = ["state"]
  profile    = "terraform"

  terraform_backend_config_file_path = "."
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = false

  tags = {
    owner = local.owner
  }
}
