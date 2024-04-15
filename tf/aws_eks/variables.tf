variable "region" {
  description = "The AWS region. Default region 'us-east-1'"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "The EKS cluster version"
  type        = string
	default     = "1.29"
}

variable "vpc_cidr" {
  description = "The VPC CIDR"
  type        = string
	default     = "10.0.0.0/16"
}

variable "tags" {
  description = "A map of exta tags for AWS resources"
  default     = null
  type        = map(any)
}
