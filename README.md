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
The TF 
```
terraform init -backend-config="../env/dvagapov1a/backend.hcl"
terraform plan -var-file=../env/dvagapov1a/values.tfvar
terraform apply -var-file=../env/dvagapov1a/values.tfvar -auto-approve
```

Apply usually takes ~15min. 
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

