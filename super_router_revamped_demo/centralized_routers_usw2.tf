locals {
  centralized_routers_usw2 = [
    {
      name            = "thunderbird"
      amazon_side_asn = 64520
      blackhole       = local.blackhole
      vpcs            = module.vpcs_usw2
      routing_policy  = local.routing_policy
    },
    {
      name            = "storm"
      amazon_side_asn = 64525
      blackhole       = local.blackhole
      vpcs            = module.vpcs_another_usw2
      routing_policy  = local.routing_policy
    }
  ]
}

module "centralized_routers_usw2" {
  #source  = "JudeQuintana/centralized-router/aws"
  #version = "1.0.6"
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=init-deny-policy"
  #source = "/Users/jude/projects/terraform-modules/networking/transit_gateway_centralized_router_for_tiered_vpc_ng"

  providers = {
    aws = aws.usw2
  }

  for_each = { for c in local.centralized_routers_usw2 : c.name => c }

  env_prefix         = var.env_prefix
  region_az_labels   = var.region_az_labels
  routing_policy     = each.value.routing_policy
  centralized_router = each.value
}
