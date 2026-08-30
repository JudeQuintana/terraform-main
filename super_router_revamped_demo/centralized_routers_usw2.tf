locals {
  centralized_routers_usw2 = [
    {
      name            = "thunderbird"
      amazon_side_asn = 64520
      routing_policy  = local.routing_policy
      vpcs            = module.vpcs_usw2
      blackhole       = local.blackhole
      inspect         = local.inspect
    },
    {
      name            = "storm"
      amazon_side_asn = 64525
      routing_policy  = local.routing_policy
      vpcs            = module.vpcs_another_usw2
      blackhole       = local.blackhole
      inspect         = local.inspect
    }
  ]
}

module "centralized_routers_usw2" {
  #source  = "JudeQuintana/centralized-router/aws"
  #version = "1.1.0"
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=reachability-provenance"

  providers = {
    aws = aws.usw2
  }

  for_each = { for c in local.centralized_routers_usw2 : c.name => c }

  env_prefix         = var.env_prefix
  region_az_labels   = var.region_az_labels
  centralized_router = each.value
}
