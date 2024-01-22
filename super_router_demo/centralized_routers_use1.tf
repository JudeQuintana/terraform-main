locals {
  centralized_routers_use1 = [
    {
      name            = "wolverine"
      amazon_side_asn = 64519
      blackhole_cidrs = local.blackhole_cidrs
      vpcs            = module.vpcs_use1
    },
    {
      name            = "bishop"
      amazon_side_asn = 64524
      blackhole_cidrs = local.blackhole_cidrs
      vpcs            = module.vpcs_another_use1
    }
  ]
}

# This TGW Centralized router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# generate and add routes in each VPC to all other networks.
module "centralized_routers_use1" {
  source = "git@github.com:JudeQuintana/terraform-aws-centralized-router.git?ref=v1.0.0"

  providers = {
    aws = aws.use1
  }

  for_each = { for c in local.centralized_routers_use1 : c.name => c }

  env_prefix         = var.env_prefix
  region_az_labels   = var.region_az_labels
  centralized_router = each.value
}
