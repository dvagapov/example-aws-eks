resource "datadog_monitor" "deployment_replicas" {
  for_each        = toset(var.deployments)
  name            = "Deployment replicas ${var.service}: kube_deployment ${each.key} replicas in {{cluster_name.name}}"
  type            = "metric alert"
  query           = "avg(last_15m):default_zero(avg:kubernetes_state.deployment.replicas_desired{kube_deployment:${each.key} AND owner:${var.owner}} by {cluster_name} - avg:kubernetes_state.deployment.replicas_available{kube_deployment:${each.key} AND owner:${var.owner}} by {cluster_name}) > 2"
  new_group_delay = var.new_group_delay

  monitor_thresholds {
    critical          = 2
    critical_recovery = 1
    warning           = 1
    warning_recovery  = 0
  }

  message            = format("%s%s", "Deployment is missing some desired replicas for a longer amount of time", local.full_message_p2)
  escalation_message = var.escalation_message

  renotify_interval = var.renotify_interval
  notify_audit      = var.notify_audit
  include_tags      = var.include_tags
  notify_no_data    = var.notify_no_data
  priority          = var.priority

  require_full_window = var.require_full_window

  tags = concat(local.tags, var.tags)
}
