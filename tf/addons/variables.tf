variable "cluster_name" {
  type        = string
  description = "k8s cluster name"
  default     = "dvagapov1a"
}

variable "environment" {
  description = "The environment. Default region 'test'"
  type        = string
  default     = "test"
}

variable "datadog_api_key" {
  type        = string
  description = "Datadog API Key"
}

variable "datadog_app_key" {
  type        = string
  description = "Datadog Application Key"
}

variable "datadog_site" {
  type        = string
  description = "Datadog Site Parameter"
  default     = "datadoghq.eu"
}

variable "datadog_api_url" {
  type        = string
  description = "Datadog API URL"
  default     = "https://api.datadoghq.eu"
}