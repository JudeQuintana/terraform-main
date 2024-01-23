locals {
  tiered_vpcs_use2 = [
    {
      name         = "app9"
      network_cidr = "192.168.128.0/20"
      azs = {
        a = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private_subnets = [
            { name = "cluster1", cidr = "192.168.128.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "192.168.132.0/24", special = true },
          ]
        }
        c = {
          private_subnets = [
            { name = "cluster2", cidr = "192.168.134.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "192.168.136.0/28", special = true },
          ]
        }
      }
    },
    {
      name         = "general9"
      network_cidr = "172.16.128.0/20"
      azs = {
        a = {
          private_subnets = [
            { name = "cluster4", cidr = "172.16.128.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "172.16.132.0/28", special = true },
          ]
        }
        c = {
          private_subnets = [
            { name = "experiment1", cidr = "172.16.135.0/24" }
          ]
          public_subnets = [
            { name = "random3", cidr = "172.16.136.0/28", special = true },
          ]
        }
      }
    }
  ]
}

module "vpcs_use2" {
  source = "git@github.com:JudeQuintana/terraform-aws-tiered-vpc-ng.git?ref=v1.0.0"

  providers = {
    aws = aws.use2
  }

  for_each = { for t in local.tiered_vpcs_use2 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

