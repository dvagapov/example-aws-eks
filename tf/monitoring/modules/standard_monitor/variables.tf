variable "enabled" {
  type        = bool
  default     = true
  description = "To enable this module"
}

variable "service" {
  type        = string
  description = "Name of addon."
}

variable "thresholds" {
  type        = map(string)
  description = "The warning and critical thresholds for this monitoring"
  default     = {}
}

variable "evaluation_delay" {
  type        = string
  default     = "0"
  description = "Time to delay evaluation in seconds"
}

variable "new_group_delay" {
  type        = number
  default     = 300
  description = "Time to skip evaluations for new groups. Default 5 minutes."
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Additional tags for this monitor"
}

variable "timeboard_id" {
  type        = string
  default     = ""
  description = "The timeboard id for this monitor"
}

variable "dashboard_id" {
  type        = string
  default     = ""
  description = "The dashboard id for this monitor (if you are using new datadog_dashboard block)"
}

variable "recipients" {
  type        = list(string)
  default     = []
  description = "Notification recipients when both alert and warning are triggered"
}

variable "alert_recipients" {
  type        = list(string)
  default     = ["pagerduty-Datadog_Infrastructure"]
  description = "Notification recipients when only alert is triggered"
}

variable "warning_recipients" {
  type        = list(string)
  default     = ["pagerduty-Datadog_Infrastructure_sev2"]
  description = "Notification recipients when only warning is triggered"
}

variable "cpu_message" {
  type        = string
  default     = "**Description:** If this alert fires, it means {{kube_container_name.name}} is almost hitting the cpu limit and we are at risk of throttling."
  description = "The message when cpu monitor triggered"
}

variable "mem_message" {
  type        = string
  default     = "**Description:** If this alert fires, it means {{kube_container_name.name}} is almost hitting the memory limit and we are at risk of OOM kill."
  description = "The message when memory monitor triggered"
}

variable "restart_message" {
  type        = string
  default     = "**Description:** If this alert fires, it means {{kube_container_name.name}} restarted several times in monitor window and should be investigated"
  description = "The message when restart monitor triggered"
}

variable "cpu_monitor" {
  description = "If CPU monitor is enabled"
  type        = bool
}

variable "memory_monitor" {
  description = "If memory monitor is enabled"
  type        = bool
}

variable "restarts_monitor" {
  description = "If restarts monitor is enabled"
  type        = bool
}

variable "deployments" {
  description = "List of deployments the service has."
  type        = list(string)
}

variable "daemonsets" {
  description = "List of daemonsets the service has."
  type        = list(string)
}

variable "statefulsets" {
  description = "List of statefulsets the service has."
  type        = list(string)
}

variable "escalation_message" {
  type        = string
  default     = ""
  description = "The escalation message when monitor isn't resolved for given time"
}

variable "renotify_interval" {
  type        = number
  default     = 0
  description = "Time interval in minutes which escalation_message will be sent when monitor is triggered"
}

variable "notify_audit" {
  type        = bool
  default     = false
  description = "Whether any configuration changes should be notified"
}

variable "priority" {
  type        = number
  default     = null
  description = "Integer from 1 (high) to 5 (low) indicating alert severity."
}

variable "include_tags" {
  type        = bool
  default     = true
  description = "Whether to include tags in name"
}

variable "require_full_window" {
  type        = bool
  default     = true
  description = "Whether require full window of data for evaluation"
}

variable "notify_no_data" {
  type        = bool
  default     = false
  description = "Notify if there is no data receive"
}

variable "no_data_timeframe" {
  type        = number
  default     = 30
  description = "Notify if there is no data receive"
}

variable "runbook_wiki" {
  type        = string
  default     = ""
  description = "Link to runbook page"
}

variable "restart_monitor_thresholds_warning" {
  type        = number
  default     = 5
  description = "Configurable warning threshold for restart monitor."
}

variable "restart_monitor_thresholds_warning_recovery" {
  type        = number
  default     = 1
  description = "Configurable warning recovery threshold for restart monitor."
}

variable "owner" {
  type        = string
  default     = "*"
  description = "Owner name that used in DD configuration for k8s agent"
}