module "centralized_router_usw2" {
  #source  = "JudeQuintana/centralized-router/aws"
  #version = "1.0.2"
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=dual-stack-full-mesh-trio"
  #source = "/Users/jude/projects/terraform-modules/networking/transit_gateway_centralized_router_for_tiered_vpc_ng"

  providers = {
    aws = aws.usw2
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "arch-angel"
    amazon_side_asn = 64521
    vpcs            = module.vpcs_usw2
    blackhole       = local.blackhole
  }
}
