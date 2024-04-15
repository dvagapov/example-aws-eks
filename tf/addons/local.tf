locals {
	namespace  = "datadog"
	name       = "datadog-agent"
	chart      = "datadog"
  repository = "https://helm.datadoghq.com"
  version    = "3.59.6"
}