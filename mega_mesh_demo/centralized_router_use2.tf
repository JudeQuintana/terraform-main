module "centralized_router_use2" {
  source = "git@github.com:JudeQuintana/terraform-aws-centralized-router.git?ref=v1.0.0"

  providers = {
    aws = aws.use2
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "apocalypse"
    amazon_side_asn = 64527
    vpcs            = module.vpcs_use2
  }
}
