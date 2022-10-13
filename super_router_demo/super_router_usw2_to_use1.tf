# Super Router is composed of two TGWs, one in each region.
module "tgw_super_router_usw2_to_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tgw_super_router_for_tgw_centralized_router?ref=v1.4.5"

  providers = {
    aws.local = aws.usw2 # local super router tgw will be built in the aws.local provider region
    aws.peer  = aws.use1 # peer super router tgw will be built in the aws.peer provider region
  }

  env_prefix                = var.env_prefix
  region_az_labels          = var.region_az_labels
  local_amazon_side_asn     = 64521
  local_centralized_routers = [module.tgw_centralized_router_usw2, module.tgw_centralized_router_usw2_another] # local list must be all same region as each other in aws.local provider.
  peer_amazon_side_asn      = 64522
  peer_centralized_routers  = [module.tgw_centralized_router_use1, module.tgw_centralized_router_use1_another] # peer list must all be same region as each other in aws.peer provider.
}

output "super_router" {
  value = module.tgw_super_router_usw2_to_use1
}
