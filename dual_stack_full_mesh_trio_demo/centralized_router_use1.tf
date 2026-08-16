module "centralized_router_use1" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.1.0"

  providers = {
    aws = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  routing_policy   = local.routing_policy
  centralized_router = {
    name            = "mystique"
    amazon_side_asn = 64519
    vpcs            = module.vpcs_use1
    blackhole       = local.blackhole
  }
}

