module "centralized_router_apse1" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.0.1"

  providers = {
    aws = aws.apse1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "gambit"
    amazon_side_asn = 64524
    vpcs            = module.vpcs_apse1
  }
}

