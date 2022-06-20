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

# peering between the super router and centralized_routers within the same region and cross region works now (within same account).
module "tgw_centralized_router_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=tgw-super-router-prep"

  providers = {
    aws = aws.usw2
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  amazon_side_asn  = 64520
  vpcs = {
    cicd = {
      az_to_private_route_table_id = {
        a = "rtb-0f8deb7a6682793e2"
      }
      az_to_public_route_table_id = {
        a = "rtb-09a4481eb3684abba"
      }
      network = "10.0.0.0/20"
    }
    other = {
      az_to_private_route_table_id = {
        a = "rtb-108deb7a668271111"
      }
      az_to_public_route_table_id = {
        a = "rtb-10a4481eb36842222"
      }
      network = "192.168.16.0/20"
    }
  }
}

module "tgw_centralized_router_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=tgw-super-router-prep"

  providers = {
    aws = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  amazon_side_asn  = 64519
  vpcs = {
    app = {
      az_to_private_route_table_id = {
        a = "rtb-0468efad92cd62ab8"
        b = "rtb-02ad79df1a7c192e7"
      }
      az_to_public_route_table_id = {
        a = "rtb-06b216fb818494594"
        b = "rtb-06b216fb818494594"
      }
      network = "172.16.0.0/20"
    }
    general = {
      az_to_private_route_table_id = {
        c = "rtb-01e5ec4882154a9a1"
      }
      az_to_public_route_table_id = {
        c = "rtb-0ad6cde89a9e386fd"
      }
      network = "192.168.0.0/20"
    }
  }
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

output "tgw_super_router_generated_local_vpc_routes" {
  value = module.tgw_super_router_usw2.generated_local_vpc_routes
}

output "tgw_super_router_generated_peer_vpc_routes" {
  value = module.tgw_super_router_usw2.generated_peer_vpc_routes
}

