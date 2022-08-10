# peering and routing between the super router and centralized_routers within the same region and cross region works now (within same aws account only).
# The caveat is the peer TGWs will have to go through the local provider region to get to other peer TGWs.
#
# ie usw2 vpc 1 <-> usw2 centralized router 1 <-> usw2 super router <-> use1 centralized router 1 <-> use1 vpc 2
#
# ie usw2 vpc 1 <-> usw2 centralized router 1 <-> usw2 super router <-> usw2 centralized router 2 <-> usw2 vpc 2
#
# ie use1 vpc 1 <-> use1 centralized router 1 <-> usw2 super router <-> use1 centralized router 2 <-> use1 vpc 2
#
module "tgw_super_router_usw2_to_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tgw_super_router_for_tgw_centralized_router?ref=tgw-super-router-prep"

  providers = {
    aws.local = aws.usw2 # super router will be built in the aws.local provider region
    aws.peer  = aws.use1
  }

  env_prefix                = var.env_prefix
  region_az_labels          = var.region_az_labels
  local_amazon_side_asn     = 64521
  local_centralized_routers = [module.tgw_centralized_router_usw2, module.tgw_centralized_router_usw2_another] # local list must be all same region as each other in aws.local provider.
  peer_centralized_routers  = [module.tgw_centralized_router_use1, module.tgw_centralized_router_use1_another] # peer list must all be same region as each other in aws.peer provider.
}
