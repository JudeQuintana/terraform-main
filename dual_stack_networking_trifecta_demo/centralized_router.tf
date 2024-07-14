# This TGW Centralized router module will attach all dual stack vpcs (attachment for each AZ) to one TGW
# and route to each other for the VPC IPv4 network cidrs, IPv4 secondary cidrs and IPv6 cidrs.
# hub and spoke
module "centralized_router" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.0.2"

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "gambit"
    amazon_side_asn = 64512
    vpcs            = module.vpcs
    blackhole = {
      cidrs      = ["172.16.8.0/24"]
      ipv6_cidrs = ["2600:1f24:66:c109::/64"]
    }
  }
}

output "centralized_router" {
  value = module.centralized_router
}
