locals {
  dummy_service_name = "dummy"
  dummy_runbook_wiki = "https://Link-to-my-wiki/runbook_id"
  dummy_monitors = {
     ssl_expiration = {
      name    = "SSL certificate {{cert_name.name}} is expired in fqdn {{fqdn.name}} in {{value}} days"
      query   = "min(last_30m):max:dummy.ssl_days_to_expire_total{owner:${var.owner}} by {cluster_name,cert_name,fqdn} - (max:cert_manager.clock_time{owner:${var.owner}} by {cluster_name} - max:dummy.ssl_days_to_expire_created{owner:${var.owner}} by {cluster_name,cert_name,fqdn}) / 86400 < 10"
      message = "SSL certificate '{{cert_name.name}}' will expired in fqdn '{{fqdn.name}}' in '{{value}}' days \n This alert is gererated by the application `dummy` in k8s cluster {{cluster_name.name}}."
      thresholds = {
        critical = 10
        warning  = 30
      }
      recipients = ["app002.sosafe@gmail.com"]
      tags       = ["owner:${var.owner}"]
    }
  }
}

module "monitor_dummy" {
  source             = "./modules/monitor"
  for_each           = local.dummy_monitors
  service            = local.dummy_service_name
  runbook_wiki       = try(local.dummy_runbook_wiki, "")

  name               = each.value.name
  type               = try(each.value.type, null)
  query              = each.value.query
  new_group_delay    = try(each.value.new_group_delay, 300)
  message            = each.value.message
  thresholds         = each.value.thresholds
  recipients         = try(each.value.recipients, [])
  alert_recipients   = try(each.value.alert_recipients, [])
  warning_recipients = try(each.value.warning_recipients, [])
  tags               = try(each.value.tags, [])
  owner              = var.owner
}