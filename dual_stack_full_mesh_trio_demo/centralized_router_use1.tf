module "centralized_router_use1" {
  #source  = "JudeQuintana/centralized-router/aws"
  #version = "1.2.0"
  source = "git@github.com:JudeQuintana/terraform-aws-centralized-router.git?ref=compiler-semantic-toolchain"

  providers = {
    aws = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "mystique"
    amazon_side_asn = 64519
    routing_policy  = local.routing_policy
    vpcs            = module.vpcs_use1
    blackhole       = local.blackhole
  }
}

