# AWS
Terraform files for deployment of VMLabAutomation

## Setup
Requires: terraform 0.14.7
In bash (git bash on windows):
1. `mv env.sh.template env.sh `
2. Fill `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in `env.sh`
3. `./env.sh`

It needs to be repeated each time unless variables are set globally.
