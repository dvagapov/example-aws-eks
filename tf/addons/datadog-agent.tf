resource "helm_release" "datadog_agent" {
  namespace  = local.namespace
	create_namespace    = true
	name       = local.name
	chart      = local.chart
  repository = local.repository
  version    = local.version
	wait       = false

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
        metricsProvider:
          enabled: false
      kubeStateMetricsCore:
        enabled: true
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

}