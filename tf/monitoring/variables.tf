variable "owner" {
  type        = string
  default     = "dvagapov"
  description = "Owner name that used in DD configuration for k8s agent"
}

variable "datadog_api_key" {
  type        = string
  description = "Datadog API Key"
}

variable "datadog_app_key" {
  type        = string
  description = "Datadog Application Key"
}

variable "datadog_api_url" {
  type        = string
  description = "Datadog API URL"
  default     = "https://api.datadoghq.eu"
}