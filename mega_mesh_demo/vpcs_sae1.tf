locals {
  tiered_vpcs_sae1 = [
    {
      name         = "app8"
      network_cidr = "10.0.128.0/20"
      azs = {
        a = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private_subnets = [
            { name = "cluster1", cidr = "10.0.128.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "10.0.130.0/28", special = true },
          ]
        }
        c = {
          private_subnets = [
            { name = "cluster2", cidr = "10.0.132.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "10.0.136.0/28", special = true },
          ]
        }
      }
    },
    {
      name         = "general8"
      network_cidr = "172.16.160.0/20"
      azs = {
        a = {
          private_subnets = [
            { name = "cluster4", cidr = "172.16.160.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "172.16.164.0/28", special = true },
          ]
        }
        c = {
          private_subnets = [
            { name = "experiment1", cidr = "172.16.168.0/28" }
          ]
          public_subnets = [
            { name = "random3", cidr = "172.16.171.0/28", special = true },
          ]
        }
      }
    }
  ]
}

module "vpcs_sae1" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.0"

  providers = {
    aws = aws.sae1
  }

  for_each = { for t in local.tiered_vpcs_sae1 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

