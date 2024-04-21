variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "The environment. Default region 'test'"
  type        = string
  default     = "test"
}