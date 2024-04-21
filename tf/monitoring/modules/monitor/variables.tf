variable "enabled" {
  type        = bool
  default     = true
  description = "To enable this module"
}

variable "type" {
  type    = string
  default = null
}

variable "name" {
  type        = string
  description = "The name for monitor"
}

variable "service" {
  type        = string
  description = "Name of addon."
}

variable "query" {
  type        = string
  description = "The query for monitor"
}

variable "thresholds" {
  type        = map(string)
  description = "The warning and critical thresholds for this monitoring"
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
  default     = []
  description = "Notification recipients when only alert is triggered"
}

variable "warning_recipients" {
  type        = list(string)
  default     = []
  description = "Notification recipients when only warning is triggered"
}

variable "message" {
  type        = string
  default     = ""
  description = "The message when monitor triggered"
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

variable "owner" {
  type        = string
  default     = "*"
  description = "Owner name that used in DD configuration for k8s agent"
}