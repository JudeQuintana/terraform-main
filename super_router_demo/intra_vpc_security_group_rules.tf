# super intra vpc access (cross region/provider) WIP

# This will create a sg rule for each vpc allowing inbound-only ports from
# all other vpc networks (excluding itself)
# Basically allowing ssh and ping communication across all VPCs.
#output "vpcs_usw2" {
#value = merge(module.vpcs_usw2, module.vpcs_usw2_another)
#}

locals {
  intra_vpc_security_group_rules = [
    {
      label     = "ssh"
      protocol  = "tcp"
      from_port = 22
      to_port   = 22
    },
    {
      label     = "ping"
      protocol  = "icmp"
      from_port = 8
      to_port   = 0
    }
  ]

  #?????????
  # better to do this to gaurantee map key uniqueness instead of merge(module.vpcs_usw2, module.vpcs_usw2_another) for each vpcs in same region which might overwrite keys
  #all_vpcs_usw2            = concat([for this in module.vpcs_usw2 : this], [for this in module.vpcs_usw2_another : this])
  #all_vpc_name_to_vpc_usw2 = { for this in local.all_vpcs_usw2 : this.name => this }

  #all_vpcs_use1            = concat([for this in module.vpcs_use1 : this], [for this in module.vpcs_use1_another : this])
  #all_vpc_name_to_vpc_use1 = { for this in local.all_vpcs_use1 : this.name => this }
  #...
  #vpcs = local.all_vpc_name_to_vpc_use1
}

module "intra_vpc_security_group_rules_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/intra_vpc_security_group_rule_for_tiered_vpc_ng?ref=moar-better"

  providers = {
    aws = aws.usw2
  }

  # dont use r.label for key so that it can be changed independently without forcing new resources
  for_each = { for r in local.intra_vpc_security_group_rules : format("%s-%s-%s", r.protocol, r.from_port, r.to_port) => r }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  intra_vpc_security_group_rule = {
    rule = each.value
    vpcs = merge(module.vpcs_usw2, module.vpcs_usw2_another)
  }
}

module "intra_vpc_security_group_rules_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/intra_vpc_security_group_rule_for_tiered_vpc_ng?ref=moar-better"

  providers = {
    aws = aws.use1
  }

  # dont use r.label for key so that it can be changed independently without forcing new resources
  for_each = { for r in local.intra_vpc_security_group_rules : format("%s-%s-%s", r.protocol, r.from_port, r.to_port) => r }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  intra_vpc_security_group_rule = {
    rule = each.value
    vpcs = merge(module.vpcs_use1, module.vpcs_use1_another)
  }
}

module "super_intra_vpc_security_group_rules_usw2_to_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/super_intra_vpc_security_group_rules?ref=moar-better"

  providers = {
    aws.local = aws.usw2
    aws.peer  = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  super_intra_vpc_security_group_rules = {
    local = {
      intra_vpc_security_group_rules = module.intra_vpc_security_group_rules_usw2
    }
    peer = {
      intra_vpc_security_group_rules = module.intra_vpc_security_group_rules_use1
    }
  }
}

#output "super_intra_vpc_rules" {
#value = module.super_intra_vpc_security_group_rules_usw2_to_use1
#}
