#!/bin/bash

apt-get install awscli jq unzip
rm packer terraform
wget -c https://releases.hashicorp.com/packer/0.11.0/packer_0.11.0_linux_amd64.zip
unzip -qu packer_0.11.0_linux_amd64.zip
wget -c https://releases.hashicorp.com/terraform/0.7.7/terraform_0.7.7_linux_amd64.zip
unzip -qu terraform_0.7.7_linux_amd64.zip

./terraform apply