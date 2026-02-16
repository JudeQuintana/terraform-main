# This will create a sg rule for each vpc allowing inbound-only ports from
# all other vpc networks (excluding itself)
# Basically allowing ssh and ping communication between all VPCs within each region
locals {
  security_group_rules = [
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

  intra_vpc_security_group_rules = { for r in local.security_group_rules : r.label => r }
}

module "intra_vpc_security_group_rules_usw2" {
  source  = "JudeQuintana/intra-vpc-security-group-rule/aws"
  version = "1.0.1"

  providers = {
    aws = aws.usw2
  }

  for_each = local.intra_vpc_security_group_rules

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  intra_vpc_security_group_rule = {
    rule = each.value
    vpcs = merge(module.vpcs_usw2, module.vpcs_another_usw2)
  }
}

module "intra_vpc_security_group_rules_use1" {
  source  = "JudeQuintana/intra-vpc-security-group-rule/aws"
  version = "1.0.1"

  providers = {
    aws = aws.use1
  }

  for_each = local.intra_vpc_security_group_rules

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  intra_vpc_security_group_rule = {
    rule = each.value
    vpcs = merge(module.vpcs_use1, module.vpcs_another_use1)
  }
}

# allowing ssh and ping communication across regions
module "super_intra_vpc_security_group_rules_usw2_to_use1" {
  source  = "JudeQuintana/super-intra-vpc-security-group-rules/aws"
  version = "1.0.1"

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

# IPv6
locals {
  ipv6_security_group_rules = [
    {
      label     = "ssh6"
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

  ipv6_intra_vpc_security_group_rules = { for r in local.ipv6_security_group_rules : r.label => r }
}

module "ipv6_intra_vpc_security_group_rules_use1" {
  source  = "JudeQuintana/ipv6-intra-vpc-security-group-rule/aws"
  version = "1.0.1"

  providers = {
    aws = aws.use1
  }

  for_each = local.ipv6_intra_vpc_security_group_rules

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  ipv6_intra_vpc_security_group_rule = {
    rule = each.value
    vpcs = merge(module.vpcs_use1, module.vpcs_another_use1)
  }
}

module "ipv6_intra_vpc_security_group_rules_usw2" {
  source  = "JudeQuintana/ipv6-intra-vpc-security-group-rule/aws"
  version = "1.0.1"

  providers = {
    aws = aws.usw2
  }

  for_each = local.ipv6_intra_vpc_security_group_rules

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  ipv6_intra_vpc_security_group_rule = {
    rule = each.value
    vpcs = merge(module.vpcs_usw2, module.vpcs_another_usw2)
  }
}


# allowing ssh and ping6 communication across regions
module "ipv6_super_intra_vpc_security_group_rules_usw2_to_use1" {
  source  = "JudeQuintana/ipv6-super-intra-vpc-security-group-rules/aws"
  version = "1.0.0"

  providers = {
    aws.local = aws.usw2
    aws.peer  = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  ipv6_super_intra_vpc_security_group_rules = {
    local = {
      ipv6_intra_vpc_security_group_rules = module.ipv6_intra_vpc_security_group_rules_usw2
    }
    peer = {
      ipv6_intra_vpc_security_group_rules = module.ipv6_intra_vpc_security_group_rules_use1
    }
  }
}
