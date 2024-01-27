locals {
  tiered_vpcs_usw2 = [
    {
      name         = "app10"
      network_cidr = "192.168.96.0/20"
      azs = {
        a = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private_subnets = [
            { name = "cluster1", cidr = "192.168.96.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "192.168.100.0/28", special = true },
          ]
        }
        c = {
          private_subnets = [
            { name = "cluster2", cidr = "192.168.103.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "192.168.106.0/28", special = true },
          ]
        }
      }
    },
    {
      name         = "general10"
      network_cidr = "10.0.160.0/20"
      azs = {
        a = {
          private_subnets = [
            { name = "cluster4", cidr = "10.0.160.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "10.0.164.0/28", special = true },
          ]
        }
        c = {
          private_subnets = [
            { name = "experiment1", cidr = "10.0.166.0/24" }
          ]
          public_subnets = [
            { name = "random3", cidr = "10.0.168.0/28", special = true },
          ]
        }
      }
    }
  ]
}

module "vpcs_usw2" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.0"

  providers = {
    aws = aws.usw2
  }

  for_each = { for t in local.tiered_vpcs_usw2 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

