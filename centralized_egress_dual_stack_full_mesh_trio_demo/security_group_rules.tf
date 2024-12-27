locals {
  # allow all ssh and ping communication between all VPCs within each region's intra-vpc security group
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
    vpcs = module.vpcs_use1
  }
}

module "intra_vpc_security_group_rules_use2" {
  source  = "JudeQuintana/intra-vpc-security-group-rule/aws"
  version = "1.0.1"

  providers = {
    aws = aws.use2
  }

  for_each = local.intra_vpc_security_group_rules

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  intra_vpc_security_group_rule = {
    rule = each.value
    vpcs = module.vpcs_use2
  }
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
    vpcs = module.vpcs_usw2
  }
}

## allow all ssh and ping communication between all VPCs across regions in each intra-vpc security group
module "full_mesh_intra_vpc_security_group_rules" {
  source  = "JudeQuintana/full-mesh-intra-vpc-security-group-rules/aws"
  version = "1.0.1"

  providers = {
    aws.one   = aws.use1
    aws.two   = aws.use2
    aws.three = aws.usw2
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  full_mesh_intra_vpc_security_group_rules = {
    one = {
      intra_vpc_security_group_rules = module.intra_vpc_security_group_rules_use1
    }
    two = {
      intra_vpc_security_group_rules = module.intra_vpc_security_group_rules_use2
    }
    three = {
      intra_vpc_security_group_rules = module.intra_vpc_security_group_rules_usw2
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
    vpcs = module.vpcs_use1
  }
}

module "ipv6_intra_vpc_security_group_rules_use2" {
  source  = "JudeQuintana/ipv6-intra-vpc-security-group-rule/aws"
  version = "1.0.1"

  providers = {
    aws = aws.use2
  }

  for_each = local.ipv6_intra_vpc_security_group_rules

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  ipv6_intra_vpc_security_group_rule = {
    rule = each.value
    vpcs = module.vpcs_use2
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
    vpcs = module.vpcs_usw2
  }
}

module "ipv6_full_mesh_intra_vpc_security_group_rules" {
  source  = "JudeQuintana/ipv6-full-mesh-intra-vpc-security-group-rules/aws"
  version = "1.0.0"

  providers = {
    aws.one   = aws.use1
    aws.two   = aws.use2
    aws.three = aws.usw2
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  ipv6_full_mesh_intra_vpc_security_group_rules = {
    one = {
      ipv6_intra_vpc_security_group_rules = module.ipv6_intra_vpc_security_group_rules_use1
    }
    two = {
      ipv6_intra_vpc_security_group_rules = module.ipv6_intra_vpc_security_group_rules_use2
    }
    three = {
      ipv6_intra_vpc_security_group_rules = module.ipv6_intra_vpc_security_group_rules_usw2
    }
  }
}
