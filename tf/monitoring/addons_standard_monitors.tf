# If pod name is differnet from addon name, override with 'name' (see aws-vpc-cni addon)
# List deployments and daemonsets in their respective lines for each addon
# If no deployment or daemonset is specified (empty lists), then no monitors for replicas will be created
locals {
  addon_monitoring = {
    aws-vpc-cni = {
      monitoring_enabled    = true
      name                  = "aws-node"
      deployments           = []
      daemonsets            = ["aws-node"]
      statefulsets          = []
      runbook_wiki          = "https://Link-to-my-wiki/runbook_id"
    }
    coredns = {
      monitoring_enabled    = true
      deployments           = ["coredns"]
      daemonsets            = []
      statefulsets          = []
      runbook_wiki          = "https://Link-to-my-wiki/runbook_id"
    }
    karpenter = {
      monitoring_enabled    = true
      deployments           = ["karpenter"]
      daemonsets            = []
      statefulsets          = []
      runbook_wiki          = "https://Link-to-my-wiki/runbook_id"
    }
    datadog = {
      monitoring_enabled    = true
      deployments           = []
      daemonsets            = ["datadog-agent"]
      statefulsets          = []
      runbook_wiki          = "https://Link-to-my-wiki/runbook_id"
    }
    datadog-agent-cluster-agent = {
      monitoring_enabled    = true
      deployments           = ["datadog-agent-cluster-agent"]
      daemonsets            = []
      statefulsets          = []
      runbook_wiki          = "https://Link-to-my-wiki/runbook_id"
    }
    kube-proxy = {
      monitoring_enabled    = true
      deployments           = []
      daemonsets            = ["kube-proxy"]
      statefulsets          = []
      runbook_wiki          = "https://Link-to-my-wiki/runbook_id"
    }
    ebs-csi-node = {
      monitoring_enabled    = true
      deployments           = []
      daemonsets            = ["ebs-csi-node"]
      statefulsets          = []
      runbook_wiki          = "https://Link-to-my-wiki/runbook_id"
    }
    ebs-csi-controller = {
      monitoring_enabled    = true
      deployments           = ["ebs-csi-controller"]
      daemonsets            = []
      statefulsets          = []
      runbook_wiki          = "https://Link-to-my-wiki/runbook_id"
    }
    cert-manager = {
      monitoring_enabled    = true
      deployments           = ["cert-manager"]
      daemonsets            = []
      statefulsets          = []
      confluence_runbook_id = "https://Link-to-my-wiki/runbook_id"
    }
    // Below possible useful addons for k8s any clusters
    metrics-server = {
      monitoring_enabled    = false
      deployments           = ["metrics-server"]
      daemonsets            = []
      statefulsets          = []
      runbook_wiki          = "https://Link-to-my-wiki/runbook_id"
    }
    external-dns = {
      monitoring_enabled    = false
      deployments           = ["external-dns"]
      daemonsets            = []
      statefulsets          = []
      runbook_wiki          = "https://Link-to-my-wiki/runbook_id"
    }
  }
}

module "addons_standard_monitors" {
  source = "./modules/standard_monitor"
  # This uses 'pod_name' if configured for 'pod_name', name of the app if not
  for_each = { for addon, settings in local.addon_monitoring : addon => {
    name                                        = try(settings.name, addon)
    deployments                                 = settings.deployments
    daemonsets                                  = settings.daemonsets
    statefulsets                                = settings.statefulsets
    cpu_monitor                                 = try(settings.cpu_monitor, true)
    memory_monitor                              = try(settings.memory_monitor, true)
    restarts_monitor                            = try(settings.restarts_monitor, true)
    restart_monitor_thresholds_warning          = try(settings.restart_monitor_thresholds_warning, 5)
    restart_monitor_thresholds_warning_recovery = try(settings.restart_monitor_thresholds_warning_recovery, 1)
    runbook_wiki                                = try(settings.runbook_wiki, "")
    } if settings.monitoring_enabled
  }
  service                                     = each.value.name
  deployments                                 = each.value.deployments
  daemonsets                                  = each.value.daemonsets
  statefulsets                                = each.value.statefulsets
  cpu_monitor                                 = each.value.cpu_monitor
  memory_monitor                              = each.value.memory_monitor
  restarts_monitor                            = each.value.restarts_monitor
  runbook_wiki                                = each.value.runbook_wiki
  restart_monitor_thresholds_warning          = each.value.restart_monitor_thresholds_warning
  restart_monitor_thresholds_warning_recovery = each.value.restart_monitor_thresholds_warning_recovery
  owner                                       = var.owner
}