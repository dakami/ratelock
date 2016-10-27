# requirements
# 
# 1. credentials in home dir "~/.aws/credentials"
# 2. local packages awscli and terraform

rm -f dynamo_local.zip 
zip dynamo_local.zip dynamo_local.py

# apply terraform configuration as transforms to AWS
#
# terraform apply 
terraform plan

