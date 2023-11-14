# This TGW Centralized router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# generate and add routes in each VPC to all other networks.
module "centralized_router_use1" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.0.0"

  providers = {
    aws = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "mystique"
    amazon_side_asn = 64519
    vpcs            = module.vpcs_use1
    blackhole_cidrs = local.blackhole_cidrs
  }
}
