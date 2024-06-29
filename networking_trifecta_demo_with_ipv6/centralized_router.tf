# This TGW Centralized router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# generate and add routes in each VPC to all other networks.
module "centralized_router" {
  #source  = "JudeQuintana/centralized-router/aws"
  #version = "1.0.1"
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=ipv6-for-tiered-vpc-ng"

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name                 = "gambit"
    amazon_side_asn      = 64512
    blackhole_cidrs      = ["172.16.8.0/24"]
    blackhole_ipv6_cidrs = ["2600:1f24:66:c109::/64"]
    vpcs                 = module.vpcs
  }
}

output "centralized_router" {
  value = module.centralized_router
}
