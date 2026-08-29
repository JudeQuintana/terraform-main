locals {
  centralized_routers_use1 = [
    {
      name            = "wolverine"
      amazon_side_asn = 64519
      routing_policy  = local.routing_policy
      vpcs            = module.vpcs_use1
      blackhole       = local.blackhole
    },
    {
      name            = "bishop"
      amazon_side_asn = 64524
      routing_policy  = local.routing_policy
      vpcs            = module.vpcs_another_use1
      blackhole       = local.blackhole
    }
  ]
}

module "centralized_routers_use1" {
  #source  = "JudeQuintana/centralized-router/aws"
  #version = "1.1.0"
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=reachability-provenance"

  providers = {
    aws = aws.use1
  }

  for_each = { for c in local.centralized_routers_use1 : c.name => c }

  env_prefix         = var.env_prefix
  region_az_labels   = var.region_az_labels
  centralized_router = each.value
}
