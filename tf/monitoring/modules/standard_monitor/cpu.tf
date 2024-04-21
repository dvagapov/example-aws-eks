resource "datadog_monitor" "cpu" {
  count = var.cpu_monitor ? 1 : 0
  name  = "CPU ${var.service}: utilisation is reaching its limits for {{kube_container_name.name}} in {{cluster_name.name}}"
  type  = "metric alert"
  query = "avg(last_5m):((avg:kubernetes.cpu.usage.total{pod_name:${var.service}-* AND owner:${var.owner}} by {kube_container_name,cluster_name} / 1000000) / avg:kubernetes.cpu.limits{pod_name:${var.service}-* AND owner:${var.owner}} by {kube_container_name,cluster_name}) * 100  > 95"
  new_group_delay = var.new_group_delay

  monitor_thresholds {
    critical          = lookup(local.thresholds, "critical", null)
    critical_recovery = lookup(local.thresholds, "critical_recovery", null)
    ok                = lookup(local.thresholds, "ok", null)
    unknown           = lookup(local.thresholds, "unknown", null)
    warning           = lookup(local.thresholds, "warning", null)
    warning_recovery  = lookup(local.thresholds, "warning_recovery", null)
  }

  message            = format("%s%s", var.cpu_message, local.full_message_p1_p2)
  escalation_message = var.escalation_message

  renotify_interval = var.renotify_interval
  notify_audit      = var.notify_audit
  include_tags      = var.include_tags
  notify_no_data    = var.notify_no_data
  priority          = var.priority

  require_full_window = var.require_full_window

  tags = concat(local.tags, var.tags)
}
