variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "region" {
  description = "The AWS region. Default region 'eu-central-1'"
  type        = string
  default     = "eu-central-1"
}
