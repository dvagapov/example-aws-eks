# AWS-EKS example
**Table of Contents**

- [AWS-EKS example](#aws-eks-example)
  - [Pre-request](#pre-request)
  - [Terraform backend](#terraform-backend)
  - [Deploy AWS EKS](#deploy-aws-eks)
    - [Verify EKS](#verify-eks)
  - [Deploy addons](#deploy-addons)
    - [Verify addons](#verify-addons)
      - [Verify Datadog](#verify-datadog)
      - [Verify Cert-manager](#verify-cert-manager)
  - [Deploy applications](#deploy-applications)
    - [Verify Apps](#verify-apps)
  - [Deploy DD monitors](#deploy-dd-monitors)
    - [Verify Monitors](#verify-monitors)
  - [Tier-down](#tier-down)
    - [Destroy Monitroing](#destroy-monitroing)
    - [Destroy Apps](#destroy-apps)
    - [Destroy Addons](#destroy-addons)
    - [Destroy AWS EKS](#destroy-aws-eks)

---

## Pre-request
- install aws cli
```
brew install awscli
```
- Configure aws cli
```
aws configure
```
- Create AWS IAM user `terrafrom` with programmatic access Only and iam policy (in this example we going to use AWS's managed policy `AdministratorAccess`, for production/staging we reccomend to follow `least privilege access`)
```
aws iam create-user \
  --user-name terraform \
  --tags '{"Key": "Name", "Value": "terraform"}' '{"Key": "owner", "Value": "dvagapov"}' '{"Key": "description", "Value": "for Terraform only"}'

aws iam attach-user-policy \
--user-name terraform \
--policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws iam create-access-key --user-name terraform > ~/aws_cred.json
```
- Using output AccessKeyId and SecretAccessKey create new profile `terraform`
```
aws configure set aws_access_key_id $(jq -r '.AccessKey.AccessKeyId' ~/aws_cred.json) --profile terraform

aws configure set aws_secret_access_key $(jq -r '.AccessKey.SecretAccessKey' ~/aws_cred.json) --profile terraform

aws configure set aws_secret_access_key $(jq -r '.AccessKey.SecretAccessKey' ~/aws_cred.json) --profile terraform

aws configure set region eu-central-1 --profile terraform
```
- Change to AWS profile to `terraform`
```
export AWS_PROFILE=terraform
```

## Terraform backend
First we need create TF backend
We going to use TF module [tfstate-backend](https://registry.terraform.io/modules/cloudposse/tfstate-backend/aws/latest)

```
cd ./tf/init-tf-configs
terraform init
terraform apply -auto-approve
```

Will be created:
- S3 bucket for storing state-file
- DynamoDB for state locks
- local file [backend.tf](./tf/init-tf-configs/backend.tf) with info about backend

## Deploy AWS EKS
The TF for deploy EKS cluster located in [./tf/aws_eks](./tf/aws_eks/).
TF code use module [terraform-aws-eks v20.8.5](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/v20.8.5)

TF apply usually takes ~15min. 
Will be created:
- VPC
- EKS
  - Fargate nodes with
  - AWS managed addons
    - CoreDNS
    - VPC CNI
    - EBS CSI
    - Kube-proxy
  - Karpenter
    - NodeClass
    - NodePool
```
env=dvagapov1a

terraform init -backend-config="../env/${env}/backend-eks.hcl"
terraform apply -var-file=../env/${env}/values.tfvar -auto-approve
```

### Verify EKS
- Get EKS kubeconfig of our cluster and set k8s context to `dvagapov1a`
```
aws eks update-kubeconfig --name dvagapov1a --region eu-central-1 --alias dvagapov1a
```
- Check ns
```
kubectl get ns
NAME              STATUS   AGE
default           Active   10h
karpenter         Active   10h
kube-node-lease   Active   10h
kube-public       Active   10h
kube-system       Active   10h
```
- Check if Karpenter UP
```
kubectl get all -n karpenter      
NAME                             READY   STATUS    RESTARTS   AGE
pod/karpenter-6888dcc847-8bmhs   1/1     Running   0          2m10s
pod/karpenter-6888dcc847-8px8g   1/1     Running   0          2m10s

NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/karpenter   ClusterIP   172.20.252.177   <none>        8000/TCP   10h

NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/karpenter   2/2     2            2           10h

NAME                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/karpenter-6888dcc847   2         2         2       2m11s
```
- To be able to use Spot nodes need to create `linked-role`
```
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com || true
{
    "Role": {
        "Path": "/aws-service-role/spot.amazonaws.com/",
        "RoleName": "AWSServiceRoleForEC2Spot",
        "RoleId": "AROAU6GDVL4TREEDK5M3H",
        "Arn": "arn:aws:iam::339712761639:role/aws-service-role/spot.amazonaws.com/AWSServiceRoleForEC2Spot",
        "CreateDate": "2024-04-15T16:09:32Z",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": [
                        "sts:AssumeRole"
                    ],
                    "Effect": "Allow",
                    "Principal": {
                        "Service": [
                            "spot.amazonaws.com"
                        ]
                    }
                }
            ]
        }
    }
}
```

## Deploy addons
For deploying k8s application we going to use TF helm and kubernetes providers.
The k8s credentials are using from `~/.kube/config`

Now deploy addons
```
cd ./tf/addons
env=dvagapov1a

// for do not store sensitive data in github
export TF_VAR_datadog_api_key="<Your-API-Key>"
export TF_VAR_datadog_app_key="<Your-APP-Key>"

terraform init -backend-config="../env/${env}/backend-addons.hcl"
terraform apply -auto-approve -var-file=../../env/${env}/values.tfvar
```

Will be created:
- DaemonSet DD-agent
- Deploy DD-cluster-agent
- Cert-manager

### Verify addons
Karpenter should create new nodes for Datadog agent and cert-manager. 
```
kubectl get nodeclaims -owide
NAME                  TYPE        ZONE            NODE                                          READY   AGE   CAPACITY   NODEPOOL        NODECLASS
default-arm46-jlz2t   m5.xlarge   eu-central-1b   ip-10-0-4-225.eu-central-1.compute.internal   True    12h   spot       default-arm46   default
```

#### Verify DataDog
```
kubectl get nodeclaims -owide
NAME            TYPE         ZONE            NODE                                          READY   AGE     CAPACITY   NODEPOOL   NODECLASS
default-bq2dz   m6g.xlarge   eu-central-1b   ip-10-0-6-187.eu-central-1.compute.internal   True    9m49s   spot       default    default
```

Let's check the DataDog namespace
```
kubectl get all -n datadog
NAME                                               READY   STATUS    RESTARTS   AGE
pod/datadog-agent-cluster-agent-679dfdc799-cbpjc   1/1     Running   0          38m
pod/datadog-agent-sxdrg                            3/3     Running   0          3m53s

NAME                                                       TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/datadog-agent                                      ClusterIP   172.20.200.141   <none>        8125/UDP,8126/TCP   38m
service/datadog-agent-cluster-agent                        ClusterIP   172.20.23.159    <none>        5005/TCP            38m
service/datadog-agent-cluster-agent-admission-controller   ClusterIP   172.20.144.58    <none>        443/TCP             38m
service/datadog-agent-cluster-agent-metrics-api            ClusterIP   172.20.13.107    <none>        8443/TCP            38m

NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/datadog-agent   1         1         1       1            1           kubernetes.io/os=linux   38m

NAME                                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/datadog-agent-cluster-agent   1/1     1            1           38m

NAME                                                     DESIRED   CURRENT   READY   AGE
replicaset.apps/datadog-agent-cluster-agent-679dfdc799   1         1         1       38m
```

For verify DataDog agent DS
```
kubectl exec ds/datadog-agent -n datadog -- agent status
...
```

`agent status` returns detailed info. Need to check if there are no errors and logs/metrics are processed well.

#### Verify Cert-manager

```
kubectl get all -n cert-manager
NAME                                           READY   STATUS    RESTARTS   AGE
pod/cert-manager-5c599f758d-fnbvg              1/1     Running   0          83m
pod/cert-manager-cainjector-584f44558c-mbflb   1/1     Running   0          91m
pod/cert-manager-webhook-76f9945d6f-bqzb2      1/1     Running   0          91m

NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/cert-manager           ClusterIP   172.20.50.93    <none>        9402/TCP   91m
service/cert-manager-webhook   ClusterIP   172.20.30.146   <none>        443/TCP    91m

NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/cert-manager              1/1     1            1           91m
deployment.apps/cert-manager-cainjector   1/1     1            1           91m
deployment.apps/cert-manager-webhook      1/1     1            1           91m

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/cert-manager-5c599f758d              1         1         1       83m
replicaset.apps/cert-manager-67b598c564              0         0         0       91m
replicaset.apps/cert-manager-cainjector-584f44558c   1         1         1       91m
replicaset.apps/cert-manager-webhook-76f9945d6f      1         1         1       91m
```


## Deploy applications
Because we do not use gitOps, will deploy k8s applications using Terraform.
All apps located in [apps dir](./tf/apps/) with sub-folders == k8s Namespace

As example I prepared [dummy app](https://github.com/sosafe-site-reliability-engineering/dummy-app).
It's simple app with expose port 8000 for the metrics.

```
cd ./tf/apps/bastian
env=dvagapov1a

terraform init -backend-config="../env/${env}/backend-apps.hcl"
terraform apply -auto-approve -var-file=../../env/${env}/values.tfvar
```

### Verify Apps
```
kubectl get pods -n bastian  
NAME                     READY   STATUS    RESTARTS   AGE
dummy-597ff9bfb4-2q2s6   1/1     Running   0          14m
```

In application's pods added Datadog annotations for parse metrics and push them to Datadog server. I use `K8s annotations AD v1` format.
```
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
```
Have to override `ssl_days_to_expire_*` metrics type, because [new ver of Openmetrics](https://github.com/DataDog/integrations-core/tree/master/openmetrics#configuration) not supported Counter type of metrics with Suffixes like `_total`, `_created` -> Better fix metrics names in application.

For verify openmetrics is successfully pushed to Datadog server
```
kubectl exec -it -n datadog -c agent datadog-agent-85tf7 -- agent check openmetrics
...
=== Series ===
[
  {
    "metric": "dummy.ssl_days_to_expire_created",
...
  {
    "metric": "dummy.ssl_days_to_expire_total",
...

Running Checks
  ==============
    
    openmetrics (4.2.0)
    -------------------
      Instance ID: openmetrics:dummy:f45ee8e3426fbab2 [OK]
      Configuration Source: container:containerd://547e0fa85d6dc858c24222ae3a4b96e21fd8e33d8f7507343f502d29f8099bd1
      Total Runs: 1
      Metric Samples: Last Run: 35, Total: 35
...
```
There `datadog-agent-85tf7` is Datadog DS agent working on same node with our application `dummy`

## Deploy DD monitors
We also want to use IaC for Monitoring using Terraform Datadog provider.
For a bit simplify we created 2 modules
- Module with [standard_monitor](./tf/monitoring/modules/standard_monitor/)
  - CPU usage
  - Memory usage
  - Deployment/StatefulSet (desired - avaliable replicas)
  - ..
- Module [monitor](./tf/monitoring/modules/monitor/) for Standartize monitors info

The usage of these standard_monitors
- [addons_standard_monitors.tf](./tf/monitoring/addons_standard_monitors.tf)
  - aws-vpc-cni
  - coredns
  - karpenter
  - datadog
  - datadog-agent-cluster-agent
  - kube-proxy
  - ebs-csi-node
  - ebs-csi-controller
  - cert-manager
- [apps_standard_monitors.tf](./tf/monitoring/apps_standard_monitors.tf)
  - dummy
- Non standard monitors located in folder [monitoring](./tf/monitoring/)
  - [cluster.tf](./tf/monitoring/cluster.tf) -> monitor for Pending pods
  - [ssl-expiration.tf](./tf/monitoring/ssl-expiration.tf) -> monitor using add `dummy` for alert then SSL-certificate close to expiration date 
    - Query logic: `SSL_days_total - to_days(Current_TS - SSL_cert_created_TS)`
    - Critical 10 days
    - Warning 30 days

```
cd ./tf/monitoring
env=dvagapov1a

// for do not store sensitive data in github
export TF_VAR_datadog_api_key="<Your-API-Key>"
export TF_VAR_datadog_app_key="<Your-APP-Key>"

terraform init -backend-config="../env/${env}/backend-monitoring.hcl"
terraform apply -auto-approve -var-file=../env/${env}/values.tfvar
```

### Verify Monitors
The easiest way to verify monitors is using [Datadog console](https://app.datadoghq.eu/monitors/manage?q=tag%3A%22owner%3Advagapov%22&order=desc&sort=name)


## Tier-down
Because all resources was created by Terraform we can destroy created resources using terraform flag `--destroy`.
You should destroy resources in the backward order
- Datadog Monitoring
- It's recommended to destroy Apps/Addons separately if they creating some resources outside kubernetes.
- Destroy AWS EKS

### Destroy Monitroing
```
cd ./tf/monitoring
env=dvagapov1a

// for do not store sensitive data in github
export TF_VAR_datadog_api_key="<Your-API-Key>"
export TF_VAR_datadog_app_key="<Your-APP-Key>"

terraform init -backend-config="../env/${env}/backend-monitoring.hcl"
terraform apply -var-file=../env/dvagapov1a/values.tfvar --destroy
```

### Destroy Apps
```
cd ./tf/apps
env=dvagapov1a

terraform init -backend-config="../env/${env}/backend-apps.hcl"
terraform apply -var-file=../../env/${env}/values.tfvar --destroy
```

### Destroy Addons
```
cd ./tf/addons
env=dvagapov1a

terraform init -backend-config="../env/${env}/backend-addons.hcl"
terraform apply -var-file=../../env/${env}/values.tfvar --destroy
```

### Destroy AWS EKS
```
cd ./tf/aws_eks
env=dvagapov1a

terraform init -backend-config="../env/${env}/backend-eks.hcl"
terraform apply -var-file=../../env/${env}/values.tfvar --destroy
```