# Super Router is composed of two TGWs, one in each region.
module "super_router_usw2_to_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tgw_super_router_for_tgw_centralized_router?ref=v1.4.6"

  providers = {
    aws.local = aws.usw2 # local super router tgw will be built in the aws.local provider region
    aws.peer  = aws.use1 # peer super router tgw will be built in the aws.peer provider region
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  super_router = {
    name            = "professor-x"
    blackhole_cidrs = local.blackhole_cidrs
    local = {
      amazon_side_asn     = 64521
      centralized_routers = module.centralized_routers_usw2
    }
    peer = {
      amazon_side_asn     = 64522
      centralized_routers = module.centralized_routers_use1
    }
  }
}

output "super_router" {
  value = module.super_router_usw2_to_use1
}
