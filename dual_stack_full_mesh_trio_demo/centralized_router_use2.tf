module "centralized_router_use2" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.0.4"

  providers = {
    aws = aws.use2
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "magneto"
    amazon_side_asn = 64520
    vpcs            = module.vpcs_use2
    blackhole       = local.blackhole
  }
}

