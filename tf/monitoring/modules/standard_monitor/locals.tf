locals {
  recipients_message        = "${length(var.recipients) > 0 ? " @" : ""}${join(" @", var.recipients)}"
  alert_message             = length(var.alert_recipients) > 0 ? "{{#is_alert}} @${join(" @", var.alert_recipients)}{{/is_alert}}" : ""
  alert_recovery_message    = length(var.alert_recipients) > 0 ? "{{#is_alert_recovery}} @${join(" @", var.alert_recipients)}{{/is_alert_recovery}}" : ""
  alert_message_p2          = length(var.warning_recipients) > 0 ? "{{#is_alert}} @${join(" @", var.warning_recipients)}{{/is_alert}}" : ""
  alert_recovery_message_p2 = length(var.warning_recipients) > 0 ? "{{#is_alert_recovery}} @${join(" @", var.warning_recipients)}{{/is_alert_recovery}}" : ""
  warning_message           = length(var.warning_recipients) > 0 ? "{{#is_warning}} @${join(" @", var.warning_recipients)}{{/is_warning}}" : ""
  warning_recovery_message  = length(var.warning_recipients) > 0 ? "{{#is_warning_recovery}} @${join(" @", var.warning_recipients)}{{/is_warning_recovery}}" : ""

  # Use this message in monitor if you want to alert P1 for critical and P2 for warnings
  full_message_p1_p2 = <<EOF
${var.dashboard_id != "" ? "Dashboard: https://app.datadoghq.com/dashboard/${var.dashboard_id}" : ""}
${var.dashboard_id == "" && var.timeboard_id != "" ? "Timeboard: https://app.datadoghq.com/dash/${var.timeboard_id}" : ""}
- Related dashboards: https://app.datadoghq.com/dashboard/lists?q=${join("+-+", [var.service])}
- Related monitors: https://app.datadoghq.com/monitors/manage?q=tag%3A%28%22${join("%22%20AND%20%22", local.tags)}%22%29
- ${var.runbook_wiki} != "" ? "Related runbook: ${var.runbook_wiki}" : "Related runbook: \""}
- Notification recipients:${local.recipients_message}${local.alert_message}${local.alert_recovery_message}${local.warning_message}${local.warning_recovery_message}
EOF

  # Use this message in monitor if you want to alert P2 for both critical and warnings
  full_message_p2 = <<EOF
${var.dashboard_id != "" ? "Dashboard: https://app.datadoghq.com/dashboard/${var.dashboard_id}" : ""}
${var.dashboard_id == "" && var.timeboard_id != "" ? "Timeboard: https://app.datadoghq.com/dash/${var.timeboard_id}" : ""}
- Related dashboards: https://app.datadoghq.com/dashboard/lists?q=${join("+-+", [var.service])}
- Related monitors: https://app.datadoghq.com/monitors/manage?q=tag%3A%28%22${join("%22%20AND%20%22", local.tags)}%22%29
- ${var.runbook_wiki} != "" ? "Related runbook: ${var.runbook_wiki}" : "Related runbook: \""}
- Notification recipients:${local.recipients_message}${local.alert_message_p2}${local.alert_recovery_message_p2}${local.warning_message}${local.warning_recovery_message}
EOF

  tags = ["service:${var.service}", "owner:${var.owner}"]
  thresholds = {
    critical          = 95
    critical_recovery = 90
    warning           = 85
    warning_recovery  = 80
  }
}
