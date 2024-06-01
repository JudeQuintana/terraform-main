module "centralized_router_cac1" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.0.1"

  providers = {
    aws = aws.cac1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "beast"
    amazon_side_asn = 64525
    vpcs            = module.vpcs_cac1
  }
}
