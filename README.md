# About this repo

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

## Terraform init
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

terraform init -backend-config="../env/${env}/backend.hcl"
terraform plan -var-file=../env/${env}/values.tfvar
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

## Deploy addons (DD agent)
For deploying k8s application we going to use TF helm and kubernetes providers.
The k8s credentials are using from `~/.kube/config`

Now deploy addons
```
cd ./tf/addons
env=dvagapov1a

// for do not store sensitive data in github
export TF_VAR_datadog_api_key="<Your-API-Key>"

terraform init -backend-config="../env/${env}/backend-addons.hcl"
terraform plan 
terraform apply -auto-approve
```

Will be created:
- DaemonSet DD-agent
- Deploy DD-cluster-agent

### Verify DataDog
Karpenter should create new nodes for Datadog agent.
```
kubectl get nodeclaims -owide
NAME            TYPE         ZONE            NODE                                          READY   AGE     CAPACITY   NODEPOOL   NODECLASS
default-bq2dz   m6g.xlarge   eu-central-1b   ip-10-0-6-187.eu-central-1.compute.internal   True    9m49s   spot       default    default
```

Let's check the DataDog namespace
```
k get all -n datadog
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

## Deploy applications
Because we do not use gitOps, will deploy k8s applications using Terraform.
All apps located in [apps dir](./tf/apps/) with sub-folders == k8s Namespace

As example I prepared [dummy app](https://github.com/sosafe-site-reliability-engineering/dummy-app).
It's simple app with expose port 8000 for the metrics.

```
cd ./tf/apps/bastian
env=dvagapov1a

terraform init -backend-config="../env/${env}/backend-apps.hcl"
terraform apply -var-file=../../env/${env}/values.tfvar
```

### Verify Apps
```
kubectl get pods -n bastian  
NAME                     READY   STATUS    RESTARTS   AGE
dummy-597ff9bfb4-2q2s6   1/1     Running   0          14m
```