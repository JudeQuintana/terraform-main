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
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
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

# This TGW Centralized router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# generate and add routes in each VPC to all other networks.
module "tgw_centralized_router_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=tgw-super-router-prep"

  providers = {
    aws = aws.usw2
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  amazon_side_asn  = 64520
  vpcs             = module.vpcs_usw2
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

module "tgw_centralized_router_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=tgw-super-router-prep"

  providers = {
    aws = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  amazon_side_asn  = 64519
  vpcs             = module.vpcs_use1
}

# peering and routing between the super router and centralized_routers within the same region and cross region works now (within same aws account only).
# The caveat is the peer TGWs will have to go through the local provider region to get to other peer TGWs.
#
# ie usw2 vpc 1 <-> usw2 centralized router 1 <-> usw2 super router <-> use1 centralized router 1 <-> use1 vpc 2
#
# ie usw2 vpc 1 <-> usw2 centralized router 1 <-> usw2 super router <-> usw2 centralized router 2 <-> usw2 vpc 2
#
# ie use1 vpc 1 <-> use1 centralized router 1 <-> usw2 super router <-> use1 centralized router 2 <-> use1 vpc 2
#
module "tgw_super_router_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tgw_super_router_for_tgw_centralized_router?ref=tgw-super-router-prep"

  providers = {
    aws.local = aws.usw2 # super router will be built in the aws.local provider region
    aws.peer  = aws.use1
  }

  env_prefix                = var.env_prefix
  region_az_labels          = var.region_az_labels
  local_amazon_side_asn     = 64521
  local_centralized_routers = [module.tgw_centralized_router_usw2] # local list must be all same region as each other in aws.local provider.
  peer_centralized_routers  = [module.tgw_centralized_router_use1] # peer list must all be same region as each other in aws.peer provider.

  # You can now add to the list above
  #local_centralized_routers = [module.tgw_centralized_router_usw2, module.tgw_centralized_router_usw2_another]
  #peer_centralized_routers  = [module.tgw_centralized_router_use1, module.tgw_centralized_router_use1_another]
}
