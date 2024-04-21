resource "kubectl_manifest" "dummy_ns" {
  yaml_body = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      labels:
        name: ${local.namespace}
      name: ${local.namespace}
  YAML
}

resource "kubectl_manifest" "dummy_deployment" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: ${local.name}
      namespace: ${local.namespace}
      labels:
        app: ${local.name}
        app.kubernetes.io/instance: ${local.name}
        app.kubernetes.io/name: ${local.name}
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: ${local.name}
          app.kubernetes.io/instance: ${local.name}
          app.kubernetes.io/name: ${local.name}
      template:
        metadata:
          labels:
            app: ${local.name}
            app.kubernetes.io/instance: ${local.name}
            app.kubernetes.io/name: ${local.name}
          annotations:
            ad.datadoghq.com/${local.name}.check_names: '["openmetrics"]'
            ad.datadoghq.com/${local.name}.init_configs: '[{}]'
            ad.datadoghq.com/${local.name}.instances: |-
              [{
                "prometheus_url": "http://%%host%%:${local.ports["metrics"]}/metrics",
                "namespace": "${local.name}",
                "metrics": [ "*" ],
                "type_overrides": {
                  "ssl_days_to_expire_total":"gauge",
                  "ssl_days_to_expire_created":"gauge" 
                },
                "send_distribution_buckets": true
              }]
        spec:
          containers:
          - name: ${local.name}
            image: bastianbretagne/sosafe-dummy-app:${local.version}
            imagePullPolicy: IfNotPresent
            ports:
              - containerPort: ${local.ports["metrics"]}
                name: metrics
                protocol: TCP
              - containerPort: ${local.ports["http"]}
                name: http
                protocol: TCP
            resources:
              requests:
                cpu: ${local.requests["cpu"]}
                memory: ${local.requests["memory"]}
              limits:
                cpu: ${local.limits["cpu"]}
                memory: ${local.limits["memory"]}
            livenessProbe:
              failureThreshold: 3
              httpGet:
                path: /metrics
                port: metrics
                scheme: HTTP
              initialDelaySeconds: 5
              periodSeconds: 10
              successThreshold: 1
              timeoutSeconds: 10
            readinessProbe:
              failureThreshold: 3
              httpGet:
                path: /metrics
                port: metrics
                scheme: HTTP
              initialDelaySeconds: 5
              periodSeconds: 10
              successThreshold: 1
              timeoutSeconds: 10
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: karpenter.sh/nodepool
                operator: DoesNotExist
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: ${local.name}
            topologyKey: kubernetes.io/hostname
      topologySpreadConstraints:
      - labelSelector:
          matchLabels:
            app: ${local.name}
        maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: ScheduleAnyway
      nodeSelector:
        kubernetes.io/arch: amd64
  YAML

  depends_on = [
    kubectl_manifest.dummy_ns
  ]
}

resource "kubectl_manifest" "dummy_pdb" {
  yaml_body = <<-YAML
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: ${local.name}
      namespace: ${local.namespace}
      labels:
        app: ${local.name}
        app.kubernetes.io/instance: ${local.name}
        app.kubernetes.io/name: ${local.name}
    spec:
      maxUnavailable: 10%
      selector:
        matchLabels:
          app: ${local.name}
          app.kubernetes.io/instance: ${local.name}
          app.kubernetes.io/name: ${local.name}
  YAML

  depends_on = [
    kubectl_manifest.dummy_app
  ]
}

resource "kubectl_manifest" "dummy_hpa" {
  yaml_body = <<-YAML
    apiVersion: autoscaling/v2
    kind: HorizontalPodAutoscaler
    metadata:
      name: ${local.name}
      namespace: ${local.namespace}
      labels:
        app: ${local.name}
        app.kubernetes.io/instance: ${local.name}
        app.kubernetes.io/name: ${local.name}
    spec:
      maxReplicas: 3
      metrics:
      - resource:
          name: cpu
          target:
            averageUtilization: 65
            type: Utilization
        type: Resource
      minReplicas: 1
      scaleTargetRef:
        apiVersion: apps/v1
        kind: Deployment
        name: ${local.name}
  YAML

  depends_on = [
    kubectl_manifest.dummy_app
  ]
}