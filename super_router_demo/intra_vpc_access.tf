## super intra vpc access (cross region/provider) WIP
#
## This will create a sg rule for each vpc allowing inbound-only ports from
## all other vpc networks (excluding itself)
## Basically allowing ssh and ping communication across all VPCs.
#locals {
#intra_vpc_access = [
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


## need precondition validation for region
#module "intra_vpc_access_usw2" {
#source = "git@github.com:JudeQuintana/terraform-modules.git//networking/intra_vpc_security_group_rule_for_tiered_vpc_ng?ref=moar-better"

#providers = {
#aws = aws.usw2
#}

#for_each = { for r in local.intra_vpc_access : r.label => r }

#env_prefix = var.env_prefix
#intra_vpc_access = {
#rule = each.value
#vpcs = merge(module.vpcs_usw2, module.vpcs_usw2_another)
#}
#}

## need precondition validation for region
#module "intra_vpc_access_use1" {
#source = "git@github.com:JudeQuintana/terraform-modules.git//networking/intra_vpc_security_group_rule_for_tiered_vpc_ng?ref=moar-better"

#providers = {
#aws = aws.use1
#}

#for_each = { for r in local.intra_vpc_access : r.label => r }

#env_prefix = var.env_prefix
#intra_vpc_access = {
#rule = each.value
#vpcs = merge(module.vpcs_use1, module.vpcs_use1_another)
#}
#}

## need precondition validation for region
#module "super_intra_vpc_access" {
#source = ""

#providers = {
#aws.local = aws.usw2
#aws.peer  = aws.use1
#}

#env_prefix = var.env_prefix
#super_intra_vpc_access = {
#local = {
#intra_vpc_access = module.intra_vpc_access_usw2
#}
#peer = {
#intra_vpc_access = module.intra_vpc_access_usw2
#}
#}
#}
