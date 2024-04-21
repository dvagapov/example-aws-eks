resource "helm_release" "cert-manager" {
  name             = local.cert-manager.name
  namespace        = local.cert-manager.namespace
  create_namespace = true
  chart            = local.cert-manager.chart
  repository       = local.cert-manager.repository
  version          = local.cert-manager.version
  wait             = false

  values = [
    <<-EOT
    global:
      podSecurityPolicy:
        enabled: false
    installCRDs: true
    podAnnotations: 
      ad.datadoghq.com/${local.cert-manager.name}.check_names: '["openmetrics"]'
      ad.datadoghq.com/${local.cert-manager.name}.init_configs: '[{}]'
      ad.datadoghq.com/${local.cert-manager.name}.instances: '[{ "prometheus_url": "http://%%host%%:9402/metrics","namespace": "${local.cert-manager.name}", "metrics": [ "*" ], "send_distribution_buckets": true }]'
    EOT
  ]
}