module "centralized_router_euw1" {
  source = "git@github.com:JudeQuintana/terraform-aws-centralized-router.git?ref=v1.0.0"

  providers = {
    aws = aws.euw1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "rogue"
    amazon_side_asn = 64522
    vpcs            = module.vpcs_euw1
  }
}
