resource "helm_release" "datadog_agent" {
  namespace        = local.datadog.namespace
  create_namespace = true
  name             = local.datadog.name
  chart            = local.datadog.chart
  repository       = local.datadog.repository
  version          = local.datadog.version
  wait             = false

  values = [
    <<-EOT
    clusterName: ${var.cluster_name}
    datadog:
      site: ${var.datadog_site}
      logs:
        enabled: true
        containerCollectAll: true
      logLevel: ERROR
      leaderElection: true
      collectEvents: true
      clusterAgent:
        enabled: true
        useHostNetwork: true
        metricsProvider:
          enabled: true
      kubeStateMetricsCore:
        enabled: true
        labelsAsTags:
          pod:
            app: app
      hostVolumeMountPropagation: HostToContainer
      tags:
        - "cluster_name:${var.cluster_name}"
        - "enviroment:test"
        - "owner:dvagapov"
    networkMonitoring:
      enabled: true
    systemProbe:
      enableTCPQueueLength: true
      enableOOMKill: true
    securityAgent:
      runtime:
        enabled: true
		EOT
  ]

  set_sensitive {
    name  = "datadog.apiKey"
    value = var.datadog_api_key
  }

  set_sensitive {
    name  = "datadog.appKey"
    value = var.datadog_app_key
  }

}