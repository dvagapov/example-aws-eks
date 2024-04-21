resource "datadog_monitor" "memory-workingset" {
  count = var.memory_monitor ? 1 : 0
  name  = "Memory ${var.service} WorkingSet: utilisation is reaching its limits for {{kube_container_name.name}} in {{cluster_name.name}}"
  type  = "metric alert"
  query = "avg(last_5m):max:kubernetes.memory.working_set{pod_name:${var.service}-* AND owner:${var.owner}} by {kube_container_name,cluster_name} / max:kubernetes.memory.limits{pod_name:${var.service}-* AND owner:${var.owner}} by {kube_container_name,cluster_name} * 100 > 95"
  new_group_delay = var.new_group_delay

  monitor_thresholds {
    critical          = lookup(local.thresholds, "critical", null)
    critical_recovery = lookup(local.thresholds, "critical_recovery", null)
    ok                = lookup(local.thresholds, "ok", null)
    unknown           = lookup(local.thresholds, "unknown", null)
    warning           = lookup(local.thresholds, "warning", null)
    warning_recovery  = lookup(local.thresholds, "warning_recovery", null)
  }


  message            = "This monitor watches workingset utilization and if it is reaching limits. This is a helper monitor for composite memory monitor below."
  escalation_message = var.escalation_message

  renotify_interval = var.renotify_interval
  notify_audit      = var.notify_audit
  include_tags      = var.include_tags
  notify_no_data    = var.notify_no_data
  priority          = var.priority

  require_full_window = var.require_full_window

  tags = concat(local.tags, var.tags)
}

resource "datadog_monitor" "memory-rss" {
  count = var.memory_monitor ? 1 : 0
  name  = "Memory ${var.service} RSS: utilisation is reaching its limits for {{kube_container_name.name}} in {{cluster_name.name}}"
  type  = "metric alert"
  query = "avg(last_5m):max:kubernetes.memory.rss{pod_name:${var.service}-* AND owner:${var.owner}} by {kube_container_name,cluster_name} / max:kubernetes.memory.limits{pod_name:${var.service}-* AND owner:${var.owner}} by {kube_container_name,cluster_name} * 100 > 95"
  new_group_delay = var.new_group_delay

  monitor_thresholds {
    critical          = lookup(local.thresholds, "critical", null)
    critical_recovery = lookup(local.thresholds, "critical_recovery", null)
    ok                = lookup(local.thresholds, "ok", null)
    unknown           = lookup(local.thresholds, "unknown", null)
    warning           = lookup(local.thresholds, "warning", null)
    warning_recovery  = lookup(local.thresholds, "warning_recovery", null)
  }

  evaluation_delay = var.evaluation_delay

  message            = "This monitor watches RSS utilization and if it is reaching limits. This is a helper monitor for composite memory monitor below."
  escalation_message = var.escalation_message

  renotify_interval = var.renotify_interval
  notify_audit      = var.notify_audit
  include_tags      = var.include_tags
  notify_no_data    = var.notify_no_data
  priority          = var.priority

  require_full_window = var.require_full_window

  tags = concat(local.tags, var.tags)
}

resource "datadog_monitor" "composite" {
  count = var.memory_monitor ? 1 : 0
  name  = "Memory ${var.service}: memory utilisation is reaching its limits for {{kube_container_name.name}} in {{cluster_name.name}}"
  type  = "composite"
  query = "${datadog_monitor.memory-rss[0].id} || ${datadog_monitor.memory-workingset[0].id}"

  message            = format("%s%s", var.mem_message, local.full_message_p1_p2)
  escalation_message = var.escalation_message

  renotify_interval = var.renotify_interval
  notify_audit      = var.notify_audit
  include_tags      = var.include_tags
  notify_no_data    = var.notify_no_data
  priority          = var.priority

  require_full_window = var.require_full_window

  tags = concat(local.tags, var.tags)
}