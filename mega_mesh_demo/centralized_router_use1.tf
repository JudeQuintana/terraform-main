module "centralized_router_use1" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.0.1"

  providers = {
    aws = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "mystique"
    amazon_side_asn = 64519
    vpcs            = module.vpcs_use1
  }
}
