locals {
  tiered_vpcs = [
    {
      name         = "app"
      network_cidr = "10.0.0.0/20"
      azs = {
        a = {
          private_subnets = [
            { name = "cluster1", cidr = "10.0.0.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "10.0.3.0/28" },
            { name = "haproxy1", cidr = "10.0.4.0/26" },
            { name = "natgw", cidr = "10.0.10.0/28", special = true }
          ]
        }
        b = {
          private_subnets = [
            { name = "cluster2", cidr = "10.0.1.0/24" },
            { name = "random2", cidr = "10.0.5.0/24" }
          ]
          public_subnets = [
            { name = "random3", cidr = "10.0.6.0/24", special = true }
          ]
        }
      }
    },
    {
      name         = "cicd"
      network_cidr = "172.16.0.0/20"
      azs = {
        b = {
          enable_natgw = true
          private_subnets = [
            { name = "jenkins1", cidr = "172.16.5.0/24" }
          ]
          public_subnets = [
            { name = "natgw", cidr = "172.16.8.0/28", special = true }
          ]
        }
      }
    },
    {
      name         = "general"
      network_cidr = "192.168.0.0/20"
      azs = {
        c = {
          private_subnets = [
            { name = "db1", cidr = "192.168.10.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "192.168.13.0/28", special = true }
          ]
        }
      }
    }
  ]
}

module "vpcs" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=moar-better"

  for_each = { for t in local.tiered_vpcs : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

# This TGW Centralized router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# generate and add routes in each VPC to all other networks.
module "centralized_router" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/centralized_router?ref=moar-better"

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  centralized_router = {
    name            = "bishop"
    amazon_side_asn = 64512
    blackhole_cidrs = ["172.16.8.0/24"]
    vpcs            = module.vpcs
  }
}

output "centralized_router" {
  value = module.centralized_router
}
