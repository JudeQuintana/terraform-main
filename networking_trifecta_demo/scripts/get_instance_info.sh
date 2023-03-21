#!/bin/bash

# pre-reqs
# - terraform
# - curl

set -euo pipefail

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

echo '# If you have awscli configured follow the instructions below otherwise you have to do it manually in the AWS console'
echo '# AWS CLI Command to copy, replace both app-vpc-default-sg-id and My.Public.IP.Here and run script ("q" to exit returned output):'
echo
echo 'aws ec2 authorize-security-group-ingress --region us-west-2 --group-id app-vpc-default-sg-id --protocol tcp --port 22 --cidr My.Public.IP.Here/32'
