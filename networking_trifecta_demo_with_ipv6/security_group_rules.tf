# This will create a sg rule for each vpc's intra-vpc security group allowing inbound-only ports from all other vpc networks (excluding itself).
# Basically allowing ssh and ping communication across all VPCs.
# intra_vpc_security_group_rules only works for ipv4, need to add ipv6 still
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
}

module "intra_vpc_security_group_rules" {
  #source  = "JudeQuintana/intra-vpc-security-group-rule/aws"
  #version = "1.0.0"
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/intra_vpc_security_group_rule_for_tiered_vpc_ng?ref=ipv6-for-tiered-vpc-ng"

  for_each = { for r in local.intra_vpc_security_group_rules : r.label => r }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  intra_vpc_security_group_rule = {
    rule = each.value
    vpcs = module.vpcs
  }
}

locals {
  ipv6_intra_vpc_security_group_rules = [
    {
      label     = "ssh"
      protocol  = "tcp"
      from_port = 22
      to_port   = 22
    },
    {
      label     = "ping6"
      protocol  = "icmpv6"
      from_port = -1
      to_port   = -1
    }
  ]
}

module "ipv6_intra_vpc_security_group_rules" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/ipv6_intra_vpc_security_group_rule_for_tiered_vpc_ng?ref=ipv6-for-tiered-vpc-ng"

  for_each = { for r in local.ipv6_intra_vpc_security_group_rules : r.label => r }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  intra_vpc_security_group_rule = {
    rule = each.value
    vpcs = module.vpcs
  }
}
