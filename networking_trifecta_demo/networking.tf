locals {
  vpc_tiers = [
    {
      azs = {
        a = {
          private = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
          public  = ["10.0.3.0/24", "10.0.4.0/24"]
        }
      }
      name    = "app"
      network = "10.0.0.0/20"
    },
    {
      azs = {
        b = {
          enable_natgw = true
          private      = ["172.16.5.0/24", "172.16.6.0/24", "172.16.7.0/24"]
          public       = ["172.16.8.0/28", "172.16.9.0/28"]
        }
      }
      name    = "cicd"
      network = "172.16.0.0/20"
    },
    {
      azs = {
        c = {
          private = ["192.168.10.0/24", "192.168.11.0/24", "192.168.12.0/24"]
          public  = ["192.168.13.0/28"]
        }
      }
      name    = "general"
      network = "192.168.0.0/20"
    }
  ]
}

module "vpcs" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=v1.4.5"

  for_each = { for t in local.vpc_tiers : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tier             = each.value
}

# This TGW Centralized router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# generate and add routes in each VPC to all other networks.
module "tgw_centralized_router" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=v1.4.5"

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  amazon_side_asn  = 64512
  vpcs             = module.vpcs
}
