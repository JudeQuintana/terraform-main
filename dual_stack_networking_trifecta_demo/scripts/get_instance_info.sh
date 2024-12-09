#!/bin/bash

# pre-reqs
# - terraform
# - curl

set -euo pipefail

echo '# module.vpcs["app"].aws_vpc.this'
app_vpc_default_sg=`terraform state show 'module.vpcs["app"].aws_vpc.this' | grep 'default_security_group_id' | cut -f2 -d '='`
echo "    default_security_group_id = $app_vpc_default_sg"
echo

echo '# aws_instance.instances["app-public"]'
terraform state show 'aws_instance.instances["app-public"]' | grep -E 'public_ip.*=.*"|private_ip.*=.*"'
terraform state show 'aws_instance.instances["app-public"]' | grep -A2 ipv6_addresses
echo

echo '# aws_instance.instances["app-isolated"]'
terraform state show 'aws_instance.instances["app-isolated"]' | grep -E 'public_ip.*=.*"|private_ip.*=.*"'
terraform state show 'aws_instance.instances["app-isolated"]' | grep -A2 ipv6_addresses
echo

echo '# aws_instance.instances["general-private"]'
terraform state show 'aws_instance.instances["general-private"]' | grep -E 'private_ip.*=.*"'
terraform state show 'aws_instance.instances["general-private"]'| grep -A2 ipv6_addresses
echo

echo '# aws_instance.instances["cicd-private"]'
terraform state show 'aws_instance.instances["cicd-private"]' | grep -E 'private_ip.*=.*"'
terraform state show 'aws_instance.instances["cicd-private"]' | grep -A2 ipv6_addresses
echo

echo '# My Public IP'
myip=`curl -s https://checkip.amazonaws.com/`
echo "$myip"
echo

echo '# If you have awscli configured follow the instructions below otherwise you have to do it manually in the AWS console'
echo '# AWS CLI Command to copy ("q" to exit returned output):'
echo
echo "aws ec2 authorize-security-group-ingress --region us-west-2 --group-id $app_vpc_default_sg --protocol tcp --port 22 --cidr $myip/32"
echo
