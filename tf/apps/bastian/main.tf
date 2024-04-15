
# Example deployment using the [bastianbretagne/sosafe-dummy-app:0.0.1](https://github.com/sosafe-site-reliability-engineering/dummy-app)
resource "kubernetes_deployment" "example" {
  metadata {
    name = "terraform-example"
		namespace = ""
    labels = {
      app = "dummy-app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "dummy-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "dummy-app"
        }
				annotations = {
					"ad.datadoghq.com/dummy.checks" = {
						"openmetrics": {
							"init_config" = [],
							"instances" = "[{openmetrics_endpoint:}']"
						}
					} 

				}
      }

      spec {
        container {
          image = "bastianbretagne/sosafe-dummy-app:0.0.2"
          name  = "dummy"
          port {
							name = "metrics"
							container_port = "8000"
					}

          resources {
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "10m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80

              http_header {
                name  = "X-Custom-Header"
                value = "Awesome"
              }
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "example" {
  metadata {
    name = "test"
		namespace = "test"
  }

  spec {
    min_replicas = 1
    max_replicas = 5

    scale_target_ref {
      kind = "Deployment"
      name = "MyApp"
    }

    behavior {
      scale_down {
        stabilization_window_seconds = 300
        select_policy                = "Min"
        policy {
          period_seconds = 120
          type           = "Pods"
          value          = 1
        }

        policy {
          period_seconds = 310
          type           = "Percent"
          value          = 100
        }
      }
      scale_up {
        stabilization_window_seconds = 600
        select_policy                = "Max"
        policy {
          period_seconds = 180
          type           = "Percent"
          value          = 100
        }
        policy {
          period_seconds = 600
          type           = "Pods"
          value          = 5
        }
      }
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "demo" {
  metadata {
    name = "demo"
  }
  spec {
    max_unavailable = "20%"
    selector {
      match_labels = {
        test = "MyExampleApp"
      }
    }
  }
}