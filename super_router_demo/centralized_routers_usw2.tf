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
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.0.0"

  providers = {
    aws = aws.usw2
  }

  for_each = { for c in local.centralized_routers_usw2 : c.name => c }

  env_prefix         = var.env_prefix
  region_az_labels   = var.region_az_labels
  centralized_router = each.value
}
