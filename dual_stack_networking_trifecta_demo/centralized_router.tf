# This TGW Centralized router module will attach all dual stack vpcs (attachment for each AZ) to one TGW
# and route to each other for the VPC IPv4 network cidrs, IPv4 secondary cidrs and IPv6 cidrs.
# hub and spoke
module "centralized_router" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.2.2"

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "gambit"
    amazon_side_asn = 64512
    routing_policy  = local.routing_policy_intra_region
    vpcs            = module.vpcs
    blackhole       = local.blackhole
    inspect         = local.inspect
  }
}

output "centralized_router" {
  value = module.centralized_router
}
