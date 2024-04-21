locals {
  datadog = {
    namespace  = "datadog"
    name       = "datadog-agent"
    chart      = "datadog"
    repository = "https://helm.datadoghq.com"
    version    = "3.59.6"
  }

  cert-manager = {
    namespace  = "cert-manager"
    name       = "cert-manager"
    chart      = "cert-manager"
    repository = "https://charts.jetstack.io"
    version    = "v1.14.2"
  }
}