resource "datadog_monitor" "statefulset_replicas" {
  for_each        = toset(var.statefulsets)
  name            = "Statefulset replicas ${var.service}: Statefulset ${each.key} replicas in {{cluster_name.name}}"
  type            = "metric alert"
  query           = "avg(last_15m):avg:kubernetes_state.statefulset.replicas_desired{kube_statefulset:${each.key} AND owner:${var.owner}} by {cluster_name,statefulset} - avg:kubernetes_state.statefulset.replicas_current{kube_statefulset:${each.key} AND owner:${var.owner}} by {cluster_name,statefulset} >= 2"
  new_group_delay = var.new_group_delay

  monitor_thresholds {
    critical          = 2
    critical_recovery = 1
    warning           = 1
    warning_recovery  = 0.5 # Leaving this with 0 will cause warnings to never clear. Datadog uses this value as `< value` which leads to a situation where we cannot reach less than 0. 
  }

  message            = format("%s%s", "Statefulset is missing some replicas for a longer amount of time.", local.full_message_p1_p2)
  escalation_message = var.escalation_message

  renotify_interval = var.renotify_interval
  notify_audit      = var.notify_audit
  include_tags      = var.include_tags
  notify_no_data    = var.notify_no_data
  priority          = var.priority

  require_full_window = var.require_full_window

  tags = concat(local.tags, var.tags)
}
