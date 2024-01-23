module "centralized_router_cac1" {
  source = "git@github.com:JudeQuintana/terraform-aws-centralized-router.git?ref=v1.0.0"

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
