#!/bin/bash

# pre-reqs
# - terraform
# - curl

set -euo pipefail

cd ../networking_trifecta_demo

echo '# aws_instance.instances["general-private"]'
terraform state show 'aws_instance.instances["general-private"]' | grep -E 'private_ip.*=.*"'
echo

echo '# aws_instance.instances["cicd-private"]'
terraform state show 'aws_instance.instances["cicd-private"]' | grep -E 'private_ip.*=.*"'
echo

echo '# aws_instance.instances["app-public"]'
terraform state show 'aws_instance.instances["app-public"]' | grep -E 'public_ip.*=.*"|private_ip.*=.*"'
echo

echo '# module.vpcs["app"].aws_vpc.this'
terraform state show 'module.vpcs["app"].aws_vpc.this' | grep default_security_group_id
echo

echo '# My Public IP'
curl https://checkip.amazonaws.com/
echo
