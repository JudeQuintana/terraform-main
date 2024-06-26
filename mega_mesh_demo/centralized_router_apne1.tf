module "centralized_router_apne1" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.0.1"

  providers = {
    aws = aws.apne1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "jean-grey"
    amazon_side_asn = 64523
    vpcs            = module.vpcs_apne1
  }
}

