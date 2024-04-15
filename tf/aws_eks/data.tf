data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

// This data using for get ECR token to public repo with Karpenter helm-chart
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.us-east-1
}
