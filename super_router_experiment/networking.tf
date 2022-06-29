provider "aws" {
  region = var.base_region
}

provider "aws" {
  alias  = "usw2"
  region = var.base_region
}

provider "aws" {
  alias  = "use1"
  region = var.cross_region
}


locals {
  vpc_tiers_usw2 = [
    {
      azs = {
        a = {
          private = ["10.0.16.0/24", "10.0.17.0/24", "10.0.18.0/24"]
          public  = ["10.0.19.0/24", "10.0.20.0/24"]
        }

      }
      name    = "app"
      network = "10.0.16.0/20"
    },
    {
      azs = {
        c = {
          private = ["192.168.16.0/24", "192.168.17.0/24", "192.168.18.0/24"]
          public  = ["192.168.19.0/28"]
        }
      }
      name    = "general"
      network = "192.168.16.0/20"
    }
  ]
}

module "vpcs_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=tgw-super-router-prep"

  providers = {
    aws = aws.usw2
  }

  for_each = { for t in local.vpc_tiers_usw2 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tier             = each.value
}

# This will create a sg rule for each vpc allowing inbound-only ports from
# all other vpc networks (excluding itself)
# Basically allowing ssh and ping communication across all VPCs.
locals {
  intra_vpc_security_group_rules_usw2 = [
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

module "intra_vpc_security_group_rules_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/intra_vpc_security_group_rule_for_tiered_vpc_ng?ref=tgw-super-router-prep"

  providers = {
    aws = aws.usw2
  }

  for_each = { for r in local.intra_vpc_security_group_rules_usw2 : r.label => r }

  env_prefix = var.env_prefix
  vpcs       = module.vpcs_usw2
  rule       = each.value
}

# This TGW Centralized router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# generate and add routes in each VPC to all other networks.

# peering between the super router and centralized_routers within the same region and cross region works now (within same account).
module "tgw_centralized_router_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=tgw-super-router-prep"

  providers = {
    aws = aws.usw2
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  amazon_side_asn  = 64520
  vpcs             = module.vpcs_usw2
  #vpcs                         = {
  #cicd                         = {
  #az_to_private_route_table_id = {
  #a                            = "rtb-0f8deb7a6682793e2"
  #}
  #az_to_public_route_table_id = {
  #a = "rtb-09a4481eb3684abba"
  #}
  #network = "10.0.0.0/20"
  #}
  #other = {
  #az_to_private_route_table_id = {
  #a = "rtb-108deb7a668271111"
  #}
  #az_to_public_route_table_id = {
  #a = "rtb-10a4481eb36842222"
  #}
  #network = "192.168.16.0/20"
  #}
  #}
}

module "tgw_centralized_router_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=tgw-super-router-prep"

  providers = {
    aws = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  amazon_side_asn  = 64519
  vpcs             = module.vpcs_use1
  #vpcs                         = {
  #app                          = {
  #az_to_private_route_table_id = {
  #a                            = "rtb-0468efad92cd62ab8"
  #b                            = "rtb-02ad79df1a7c192e7"
  #}
  #az_to_public_route_table_id = {
  #a = "rtb-06b216fb818494594"
  #b = "rtb-06b216fb818494594"
  #}
  #network = "172.16.0.0/20"
  #}
  #general = {
  #az_to_private_route_table_id = {
  #c = "rtb-01e5ec4882154a9a1"
  #}
  #az_to_public_route_table_id = {
  #c = "rtb-0ad6cde89a9e386fd"
  #}
  #network = "192.168.0.0/20"
  #}
  #}
}

locals {
  vpc_tiers_use1 = [
    {
      azs = {
        a = {
          private = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
          public  = ["10.0.3.0/24", "10.0.4.0/24"]
        }
      }
      name    = "app"
      network = "10.0.0.0/20"
    },
    {
      azs = {
        c = {
          private = ["192.168.10.0/24", "192.168.11.0/24", "192.168.12.0/24"]
          public  = ["192.168.13.0/28"]
        }
      }
      name    = "general"
      network = "192.168.0.0/20"
    }
  ]
}

module "vpcs_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=tgw-super-router-prep"

  providers = {
    aws = aws.use1
  }

  for_each = { for t in local.vpc_tiers_use1 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tier             = each.value
}

# This will create a sg rule for each vpc allowing inbound-only ports from
# all other vpc networks (excluding itself)
# Basically allowing ssh and ping communication across all VPCs.
locals {
  intra_vpc_security_group_rules_use1 = [
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

module "intra_vpc_security_group_rules_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/intra_vpc_security_group_rule_for_tiered_vpc_ng?ref=tgw-super-router-prep"

  providers = {
    aws = aws.use1
  }

  for_each = { for r in local.intra_vpc_security_group_rules_use1 : r.label => r }

  env_prefix = var.env_prefix
  vpcs       = module.vpcs_use1
  rule       = each.value
}

module "tgw_super_router_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tgw_super_router_for_tgw_centralized_router?ref=tgw-super-router-prep"

  providers = {
    aws.local = aws.usw2 # super router will be built in the aws.local provider region
    aws.peer  = aws.use1
  }

  env_prefix                = var.env_prefix
  region_az_labels          = var.region_az_labels
  local_amazon_side_asn     = 64521
  local_centralized_routers = [module.tgw_centralized_router_usw2] # local list must be all same region as each other in aws.local provider. maybe this should be a map instead?
  peer_centralized_routers  = [module.tgw_centralized_router_use1] # peer list must all be same region as each other in aws.peer provider. maybe this should be a map instead?
}
