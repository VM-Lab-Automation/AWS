# AWS
Terraform files for deployment of VMLabAutomation

## Setup
Requires: terraform 0.14.7 \
Navigate to Amazon AWS Console and copy credentials in format:\
```
[default]
aws_access_key_id=
aws_secret_access_key=
aws_session_token=
```
Paste them in `./.aws/credentials`
Then in the main folder type:
`terraform -chdir=scripts init`
And at the end `terraform -chdir=scripts apply -var-file=../env/dev.tfvars`