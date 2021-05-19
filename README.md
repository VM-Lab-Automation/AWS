# VMLab Automation AWS Deployment
Terraform files for fully-automated deployment of VMLabAutomation on ECS cluster on AWS. Basic configuration contains database, app and selected number of worker instences. 
The deployed system is described [here](https://github.com/VM-Lab-Automation/VM-Lab-Automation). 

Repository includes two main parts:
1. `app` folder which contains terraform code needed for app deployment.
2. `ami` folder which contains some packer files to build Amazon AMIs for workers and P4 lab. Also terraform with bucket and role needed for ami import is included there.

## Setup app
Requires: terraform 0.14.7 

1. Navigate to Amazon AWS Console and copy credentials in format:
```
[default]
aws_access_key_id=
aws_secret_access_key=
aws_session_token=
```
2. Paste them in `./.aws/credentials`
3. `cd ami`
4. Create ami using packer `packer build amis/amzn_ecs_worker.pkr.hcl` and copy ami id into `var.cluster_ami`
5. `cd app`
6. Run `cp ./env/secret.template.tfvars ./env/secret.tfvars` and paste required credentials there
7. Then in the `app` folder type: `terraform -chdir=scripts init`
8. `terraform -chdir=scripts apply -var-file=../env/dev.tfvars -var-file=../env/secret.tfvars` 
9. Enjoy! 

## Create P4 AMI 
1. `cd ami/p4-machine`
2. `vagrant up`
3. Stop machine manually (shutdown doesn't work well)
4. `cd ..`
5. `packer build p4lab.pkr.hcl` 

## Lesson learned
AWS doesn't support nested virtualization on smaller instances...