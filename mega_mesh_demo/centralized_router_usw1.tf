module "centralized_router_usw1" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.0.1"

  providers = {
    aws = aws.usw1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "magneto"
    amazon_side_asn = 64520
    vpcs            = module.vpcs_usw1
  }
}
