# This TGW Centralized router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# generate and add routes in each VPC to all other networks.
module "centralized_router" {
  source  = "JudeQuintana/centralized-router/aws"
  version = "1.0.0"

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "gambit"
    amazon_side_asn = 64512
    blackhole_cidrs = ["172.16.8.0/24"]
    vpcs            = module.vpcs
  }
}

output "centralized_router" {
  value = module.centralized_router
}
