module "centralized_router_use1" {
  #source  = "JudeQuintana/centralized-router/aws"
  #version = "1.0.6"
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=init-deny-policy"

  providers = {
    aws = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "mystique"
    amazon_side_asn = 64519
    vpcs            = module.vpcs_use1
    blackhole       = local.blackhole
    policy = {
      deny = [
        { from = lookup(module.vpcs_use1, "app3"), to = lookup(module.vpcs_use1, "infra3") }
      ]
    }
  }
}

