resource "datadog_monitor" "daemonset_replicas" {
  for_each        = toset(var.daemonsets)
  name            = "Daemonset replicas ${var.service}: Daemonset ${each.key} replicas in {{cluster_name.name}}"
  type            = "metric alert"
  query           = "avg(last_15m):default_zero(max:kubernetes_state.pod.status_phase{kube_daemon_set:${each.key}, pod_phase:pending,owner:${var.owner}} by {cluster_name,kube_daemon_set,pod_name}) > 1"
  new_group_delay = var.new_group_delay

  monitor_thresholds {
    critical          = 1
  }

  message            = format("%s%s", "Daemonset is missing some replicas for a longer amount of time.", local.full_message_p1_p2)
  escalation_message = var.escalation_message

  renotify_interval = var.renotify_interval
  notify_audit      = var.notify_audit
  include_tags      = var.include_tags
  notify_no_data    = "true" # we want no-data to fire for all daemonsets
  priority          = var.priority

  require_full_window = var.require_full_window

  tags = concat(local.tags, var.tags)
}
