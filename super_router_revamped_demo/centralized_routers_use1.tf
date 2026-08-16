locals {
  centralized_routers_use1 = [
    {
      name            = "wolverine"
      amazon_side_asn = 64519
      blackhole       = local.blackhole
      vpcs            = module.vpcs_use1
      routing_policy  = local.routing_policy
    },
    {
      name            = "bishop"
      amazon_side_asn = 64524
      blackhole       = local.blackhole
      vpcs            = module.vpcs_another_use1
      routing_policy  = local.routing_policy
    }
  ]
}

module "centralized_routers_use1" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.1.0"

  providers = {
    aws = aws.use1
  }

  for_each = { for c in local.centralized_routers_use1 : c.name => c }

  env_prefix         = var.env_prefix
  region_az_labels   = var.region_az_labels
  routing_policy     = each.value.routing_policy
  centralized_router = each.value
}
