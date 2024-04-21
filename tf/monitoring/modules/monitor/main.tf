locals {
  recipients_message       = "${length(var.recipients) > 0 ? " @" : ""}${join(" @", var.recipients)}"
  alert_message            = length(var.alert_recipients) > 0 ? "{{#is_alert}} @${join(" @", var.alert_recipients)}{{/is_alert}}" : ""
  alert_recovery_message   = length(var.alert_recipients) > 0 ? "{{#is_alert_recovery}} @${join(" @", var.alert_recipients)}{{/is_alert_recovery}}" : ""
  warning_message          = length(var.warning_recipients) > 0 ? "{{#is_warning}} @${join(" @", var.warning_recipients)}{{/is_warning}}" : ""
  warning_recovery_message = length(var.warning_recipients) > 0 ? "{{#is_warning_recovery}} @${join(" @", var.warning_recipients)}{{/is_warning_recovery}}" : ""

  full_message = <<EOF
${var.message}
${var.dashboard_id != "" ? "Dashboard: https://app.datadoghq.com/dashboard/${var.dashboard_id}" : ""}
${var.dashboard_id == "" && var.timeboard_id != "" ? "Timeboard: https://app.datadoghq.com/dash/${var.timeboard_id}" : ""}
- Related dashboards: https://app.datadoghq.com/dashboard/lists?q=${join("+-+", [var.service])}
- Related monitors: https://app.datadoghq.com/monitors/manage?q=tag%3A%28%22${join("%22%20AND%20%22", local.tags)}%22%29
- ${var.runbook_wiki} != "" ? "Related runbook: ${var.runbook_wiki}" : "Related runbook: \""}
- Notification recipients:${local.recipients_message}${local.alert_message}${local.alert_recovery_message}${local.warning_message}${local.warning_recovery_message}
EOF

  tags = ["service:${var.service}", "owner:${var.owner}"]
}

resource "datadog_monitor" "addon" {
  name = var.name
  type = coalesce(var.type, "metric alert")

  query = var.query

  monitor_thresholds {
    critical          = lookup(var.thresholds, "critical", null)
    critical_recovery = lookup(var.thresholds, "critical_recovery", null)
    ok                = lookup(var.thresholds, "ok", null)
    unknown           = lookup(var.thresholds, "unknown", null)
    warning           = lookup(var.thresholds, "warning", null)
    warning_recovery  = lookup(var.thresholds, "warning_recovery", null)
  }

  evaluation_delay = var.evaluation_delay
  new_group_delay  = var.new_group_delay

  message            = local.full_message
  escalation_message = var.escalation_message

  renotify_interval = var.renotify_interval
  notify_audit      = var.notify_audit
  include_tags      = var.include_tags
  notify_no_data    = var.notify_no_data
  no_data_timeframe = var.no_data_timeframe
  priority          = var.priority

  require_full_window = var.require_full_window
  enable_logs_sample  = var.type == "log alert" ? true : false

  tags = concat(local.tags, var.tags)
}
