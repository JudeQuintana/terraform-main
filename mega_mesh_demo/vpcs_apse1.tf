locals {
  tiered_vpcs_apse1 = [
    {
      name         = "app6"
      network_cidr = "10.0.64.0/20"
      azs = {
        a = {
          private_subnets = [
            { name = "cluster1", cidr = "10.0.64.0/24", special = true }
          ]
        }
        b = {
          private_subnets = [
            { name = "cluster2", cidr = "10.0.70.0/24" }
          ]
          # Enable a NAT Gateway for all private subnets in the same AZ
          # by adding the `natgw = true` attribute to any public subnet
          public_subnets = [
            { name = "random2", cidr = "10.0.72.0/28", special = true },
          ]
        }
      }
    },
    {
      name         = "general6"
      network_cidr = "192.168.64.0/20"
      azs = {
        a = {
          private_subnets = [
            { name = "cluster4", cidr = "192.168.64.0/24", special = true }
          ]
        }
        c = {
          public_subnets = [
            { name = "random3", cidr = "192.168.79.0/28", special = true },
          ]
        }
      }
    }
  ]
}

module "vpcs_apse1" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.1"

  providers = {
    aws = aws.apse1
  }

  for_each = { for t in local.tiered_vpcs_apse1 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

