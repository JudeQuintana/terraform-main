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
  vpcs             = {}
}

module "tgw_centralized_router_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=tgw-super-router-prep"

  providers = {
    aws = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  amazon_side_asn  = 64519
  vpcs             = {}
}

module "tgw_super_router_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tgw_super_router_for_tgw_centralized_router?ref=tgw-super-router-prep"

  providers = {
    aws.local = aws.usw2
    aws.peer  = aws.use1
  }

  env_prefix                = var.env_prefix
  region_az_labels          = var.region_az_labels
  local_amazon_side_asn     = 64521
  local_centralized_routers = [module.tgw_centralized_router_usw2] # maybe this should be a map instead?
  peer_centralized_routers  = [module.tgw_centralized_router_use1] # maybe this should be a map instead?
}
