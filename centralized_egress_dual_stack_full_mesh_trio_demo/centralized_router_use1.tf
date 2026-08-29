module "centralized_router_use1" {
  #source  = "JudeQuintana/centralized-router/aws"
  #version = "1.1.0"
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=reachability-provenance"
  #source = "/Users/jude/projects/terraform-modules/networking/transit_gateway_centralized_router_for_tiered_vpc_ng"

  providers = {
    aws = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "mystique"
    amazon_side_asn = 64519
    routing_policy  = local.routing_policy_intra_region_use1
    vpcs            = module.vpcs_use1
    blackhole       = local.blackhole
  }
}

