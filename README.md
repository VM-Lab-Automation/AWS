# AWS
Terraform files for deployment of VMLabAutomation

## Setup
Requires: terraform 0.14.7 \

1. Navigate to Amazon AWS Console and copy credentials in format:\
```
[default]
aws_access_key_id=
aws_secret_access_key=
aws_session_token=
```
1. Paste them in `./.aws/credentials`
1. Run `cp ./env/secret.template.tfvars ./env/secret.tfvars` and paste required credentials there
1. IN FUTURE: Create ami using packer `command here`
1. Then in the main folder type: `terraform -chdir=scripts init`
1. `terraform -chdir=scripts apply -var-file=../env/dev.tfvars -var-file=../env/secret.tfvars` 
1. Enjoy! 