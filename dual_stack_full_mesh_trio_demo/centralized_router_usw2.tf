module "centralized_router_usw2" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.0.3"

  providers = {
    aws = aws.usw2
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "arch-angel"
    amazon_side_asn = 64521
    vpcs            = module.vpcs_usw2
    blackhole       = local.blackhole
  }
}
