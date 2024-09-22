#locals {
## allow all ssh and ping communication between all VPCs within each region's intra-vpc security group
#intra_vpc_security_group_rules = [
#{
#label     = "ssh"
#protocol  = "tcp"
#from_port = 22
#to_port   = 22
#},
#{
#label     = "ping"
#protocol  = "icmp"
#from_port = 8
#to_port   = 0
#}
#]
#}

#module "intra_vpc_security_group_rules_use1" {
#source  = "JudeQuintana/intra-vpc-security-group-rule/aws"
#version = "1.0.0"

#providers = {
#aws = aws.use1
#}

#for_each = { for r in local.intra_vpc_security_group_rules : r.label => r }

#env_prefix       = var.env_prefix
#region_az_labels = var.region_az_labels
#intra_vpc_security_group_rule = {
#rule = each.value
#vpcs = module.vpcs_use1
#}
#}

#module "intra_vpc_security_group_rules_use2" {
#source  = "JudeQuintana/intra-vpc-security-group-rule/aws"
#version = "1.0.0"

#providers = {
#aws = aws.use2
#}

#for_each = { for r in local.intra_vpc_security_group_rules : r.label => r }

#env_prefix       = var.env_prefix
#region_az_labels = var.region_az_labels
#intra_vpc_security_group_rule = {
#rule = each.value
#vpcs = module.vpcs_use2
#}
#}

#module "intra_vpc_security_group_rules_usw2" {
#source  = "JudeQuintana/intra-vpc-security-group-rule/aws"
#version = "1.0.0"

#providers = {
#aws = aws.usw2
#}

#for_each = { for r in local.intra_vpc_security_group_rules : r.label => r }

#env_prefix       = var.env_prefix
#region_az_labels = var.region_az_labels
#intra_vpc_security_group_rule = {
#rule = each.value
#vpcs = module.vpcs_usw2
#}
#}

## allow all ssh and ping communication between all VPCs across regions in each intra-vpc security group
#module "full_mesh_intra_vpc_security_group_rules" {
#source  = "JudeQuintana/full-mesh-intra-vpc-security-group-rules/aws"
#version = "1.0.1"

#providers = {
#aws.one   = aws.use1
#aws.two   = aws.use2
#aws.three = aws.usw2
#}

#env_prefix       = var.env_prefix
#region_az_labels = var.region_az_labels
#full_mesh_intra_vpc_security_group_rules = {
#one = {
#intra_vpc_security_group_rules = module.intra_vpc_security_group_rules_use1
#}
#two = {
#intra_vpc_security_group_rules = module.intra_vpc_security_group_rules_use2
#}
#three = {
#intra_vpc_security_group_rules = module.intra_vpc_security_group_rules_usw2
#}
#}
#}

