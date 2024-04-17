################################################################################
# Karpenter
################################################################################

module "karpenter" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-eks.git//modules/karpenter?ref=v20.8.5"

  cluster_name = module.eks.cluster_name

  # EKS Fargate currently does not support Pod Identity
  enable_irsa            = true
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn

  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = merge(local.tags,var.tags)
}

################################################################################
# Karpenter Helm chart & manifests
# Not required; just to demonstrate functionality of the sub-module
################################################################################

resource "helm_release" "karpenter" {
  namespace           = "karpenter"
  create_namespace    = true
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "0.35.1"
  wait                = false

  values = [
    <<-EOT
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    tolerations:
      - key: 'eks.amazonaws.com/compute-type'
        operator: Equal
        value: fargate
        effect: "NoSchedule"
    controller:
      resources:
        requests:
          cpu: 100m
          memory: 500Mi
        limits:
          cpu: 1000m
          memory: 1Gi
    EOT
  ]
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2
      role: ${module.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_ondemand_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: ondemand
    spec:
      amiFamily: AL2
      role: ${module.karpenter.node_iam_role_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
        nodepool: ondemand
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_default_arm64_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default-arm46
    spec:
      template:
        metadata:
          labels:
            nodepool: spot
            spot: "true"
        spec:
          kubelet: {}
          nodeClassRef:
            name: default
          requirements:
            - key: karpenter.k8s.aws/instance-category
              operator: In
              values:
                - c
                - m
                - r
                - i
            - key: karpenter.k8s.aws/instance-cpu
              operator: In
              values:
                - "4"
                - "8"
                - "12"
                - "16"
                - "32"
                - "48"
                - "64"
            - key: karpenter.k8s.aws/instance-hypervisor
              operator: In
              values:
                - nitro
            - key: karpenter.k8s.aws/instance-generation
              operator: Gt
              values:
                - "2"
            - key: karpenter.sh/capacity-type
              operator: In
              values:
                - spot
            - key: kubernetes.io/arch
              operator: In
              values: 
                - arm64
            - key: kubernetes.io/os
              operator: In
              values: 
                - linux
      disruption:
        consolidationPolicy: WhenUnderutilized
        expireAfter: 168h0m0s
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

resource "kubectl_manifest" "karpenter_default_amd64_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default-arm46
    spec:
      template:
        metadata:
          labels:
            nodepool: spot
            spot: "true"
        spec:
          kubelet: {}
          nodeClassRef:
            name: default
          requirements:
            - key: karpenter.k8s.aws/instance-category
              operator: In
              values:
                - c
                - m
                - r
                - i
            - key: karpenter.k8s.aws/instance-cpu
              operator: In
              values:
                - "4"
                - "8"
                - "12"
                - "16"
                - "32"
                - "48"
                - "64"
            - key: karpenter.k8s.aws/instance-hypervisor
              operator: In
              values:
                - nitro
            - key: karpenter.k8s.aws/instance-generation
              operator: Gt
              values:
                - "2"
            - key: karpenter.sh/capacity-type
              operator: In
              values:
                - spot
            - key: kubernetes.io/arch
              operator: In
              values: 
                - amd64
            - key: kubernetes.io/os
              operator: In
              values: 
                - linux
      disruption:
        consolidationPolicy: WhenUnderutilized
        expireAfter: 168h0m0s
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

resource "kubectl_manifest" "karpenter_ondemand_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: ondemand
    spec:
      template:
        metadata:
          labels:
            nodepool: ondemand
            spot: "false"
        spec:
          kubelet: {}
          nodeClassRef:
            name: ondemand
          requirements:
            - key: karpenter.k8s.aws/instance-category
              operator: In
              values:
                - c
                - m
                - r
                - i
            - key: karpenter.k8s.aws/instance-cpu
              operator: In
              values:
                - "4"
                - "8"
                - "12"
                - "16"
                - "32"
                - "48"
                - "64"
            - key: karpenter.k8s.aws/instance-hypervisor
              operator: In
              values:
                - nitro
            - key: karpenter.k8s.aws/instance-generation
              operator: Gt
              values:
                - "2"
            - key: karpenter.sh/capacity-type
              operator: In
              values:
                - on-demand
          taints:
            - effect: NoSchedule
              key: dedicated
              value: ondemand
      disruption:
        consolidateAfter: 5m0s
        consolidationPolicy: WhenEmpty
        expireAfter: Never
  YAML

  depends_on = [
    kubectl_manifest.karpenter_ondemand_node_class
  ]
}

    