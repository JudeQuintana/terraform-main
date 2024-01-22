module "centralized_router_usw2" {
  #source  = "JudeQuintana/centralized-router/aws"
  #version = "1.0.0"
  source = "git@github.com:JudeQuintana/terraform-aws-centralized-router.git?ref=v1.0.0"

  providers = {
    aws = aws.usw2
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "storm"
    amazon_side_asn = 64528
    vpcs            = module.vpcs_usw2
  }
}

