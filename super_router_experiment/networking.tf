# Trying to get peering working between the super router and centralized_router within the same region
module "tgw_centralized_router" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=tgw-super-router-prep"

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  amazon_side_asn  = 64520
  #vpcs            = module.vpcs
}

module "tgw_super_router" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tgw_super_router_for_tgw_centralized_router?ref=tgw-super-router-prep"

  providers = {
    aws.local = aws
  }

  env_prefix                = var.env_prefix
  region_az_labels          = var.region_az_labels
  local_amazon_side_asn     = 64521
  local_centralized_routers = [module.tgw_centralized_router]
}
