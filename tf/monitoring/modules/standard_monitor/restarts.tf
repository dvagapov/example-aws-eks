resource "datadog_monitor" "restarts" {
  count           = var.restarts_monitor ? 1 : 0
  name            = "Restarts ${var.service}: Container restarting often: {{kube_container_name.name}} in {{cluster_name.name}}"
  type            = "metric alert"
  query           = "sum(last_30m):default_zero(monotonic_diff(sum:kubernetes.containers.restarts{pod_name:${var.service}-* AND owner:${var.owner}} by {kube_container_name,cluster_name})) > 100"
  new_group_delay = var.new_group_delay

  monitor_thresholds {
    critical          = 100
    critical_recovery = 50
    warning           = var.restart_monitor_thresholds_warning
    warning_recovery  = var.restart_monitor_thresholds_warning_recovery
  }

  message            = format("%s%s", var.restart_message, local.full_message_p1_p2)
  escalation_message = var.escalation_message

  renotify_interval = var.renotify_interval
  notify_audit      = var.notify_audit
  include_tags      = var.include_tags
  notify_no_data    = var.notify_no_data
  priority          = var.priority

  require_full_window = var.require_full_window

  tags = concat(local.tags, var.tags)
}
