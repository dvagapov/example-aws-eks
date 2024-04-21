locals {
  owner                = "dvagapov"
  cluster_service_name = "cluster"
  cluster_monitors = {
    all-pods-pending = {
      name    = "More than 30% of pods are Pending in {{cluster_name.name}}"
      query   = "min(last_30m):default_zero(sum:kubernetes_state.pod.status_phase{pod_phase:pending AND owner:${var.owner}} by {cluster_name}) / (default_zero(sum:kubernetes_state.pod.status_phase{pod_phase:pending AND owner:${var.owner}} by {cluster_name}) + sum:kubernetes_state.pod.status_phase{pod_phase:running AND owner:${var.owner}} by {cluster_name}) * 100 > 30"
      message = "This alert reports when there is unexpected high latency during scheduling process of kube-scheduler in {{cluster_name.name}}.\n\n[Runbook for investigation of K8s core components](https://Link-to-my-wiki/runbook_id)"
      thresholds = {
        critical = 30,
        warning  = 28
      }
      recipients = ["app002.sosafe@gmail.com"]
      tags       = ["owner:${var.owner}"]
    }
  }
}

module "monitor_cluster" {
  source   = "./modules/monitor"
  for_each = local.cluster_monitors
  service  = local.cluster_service_name

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