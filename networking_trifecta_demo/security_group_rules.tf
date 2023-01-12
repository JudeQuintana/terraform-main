# This will create a sg rule for each vpc allowing inbound-only ports from
# all other vpc networks (excluding itself)
# Basically allowing ssh and ping communication across all VPCs.
locals {
  intra_vpc_security_group_rules = [
    {
      label     = "ssh"
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
    },
    {
      label     = "ping"
      from_port = 8
      to_port   = 0
      protocol  = "icmp"
    }
  ]
}

module "intra_vpc_security_group_rules" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/intra_vpc_security_group_rule_for_tiered_vpc_ng?ref=moar-better"

  for_each = { for r in local.intra_vpc_security_group_rules : r.label => r }

  env_prefix = var.env_prefix
  vpcs       = module.vpcs
  rule       = each.value
}

