locals {
  centralized_routers_usw2 = [
    {
      name            = "thunderbird"
      amazon_side_asn = 64520
      blackhole_cidrs = local.blackhole_cidrs
      vpcs            = module.vpcs_usw2
    },
    {
      name            = "storm"
      amazon_side_asn = 64525
      blackhole_cidrs = local.blackhole_cidrs
      vpcs            = module.vpcs_another_usw2
    }
  ]
}

module "centralized_routers_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=v1.4.8"

  providers = {
    aws = aws.usw2
  }

  for_each = { for c in local.centralized_routers_usw2 : c.name => c }

  env_prefix         = var.env_prefix
  region_az_labels   = var.region_az_labels
  centralized_router = each.value
}
