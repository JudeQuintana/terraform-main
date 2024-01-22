module "centralized_router_sae1" {
  source = "git@github.com:JudeQuintana/terraform-aws-centralized-router.git?ref=v1.0.0"

  providers = {
    aws = aws.sae1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "wolverine"
    amazon_side_asn = 64526
    vpcs            = module.vpcs_sae1
  }
}

