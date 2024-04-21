# If pod name is differnet from app name, override with 'name'
# List deployments and daemonsets in their respective lines for each app
# If no deployment or daemonset is specified (empty lists), then no monitors for replicas will be created
locals {
  apps_monitoring = {
    dummy = {
      monitoring_enabled    = true
      deployments           = ["dummy"]
      daemonsets            = []
      statefulsets          = []
      confluence_runbook_id = "https://Link-to-my-wiki/runbook_id"
    }
  }
}

module "apps_standard_monitors" {
  source = "./modules/standard_monitor"
  # This uses 'pod_name' if configured for 'pod_name', name of the app if not
  for_each = { for app, settings in local.apps_monitoring : app => {
    name                                        = try(settings.name, app)
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