module "centralized_router_euc1" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.0.1"

  providers = {
    aws = aws.euc1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "arch-angel"
    amazon_side_asn = 64521
    vpcs            = module.vpcs_euc1
  }
}
