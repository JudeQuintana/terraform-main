locals {
  tiered_vpcs_usw2 = [
    {
      name         = "app1"
      network_cidr = "10.0.16.0/20"
      azs = {
        a = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private_subnets = [
            { name = "cluster1", cidr = "10.0.16.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "10.0.19.0/28", special = true },
            { name = "haproxy1", cidr = "10.0.21.64/26" }
          ]
        }
        b = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private_subnets = [
            { name = "cluster2", cidr = "10.0.27.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "10.0.30.0/28", special = true },
            { name = "haproxy2", cidr = "10.0.31.64/26" }
          ]
        }
      }
    },
    {
      name         = "general1"
      network_cidr = "192.168.16.0/20"
      azs = {
        c = {
          private_subnets = [
            { name = "experiment1", cidr = "192.168.16.0/24" }
          ]
          public_subnets = [
            { name = "random3", cidr = "192.168.19.0/28", special = true },
            { name = "haproxy3", cidr = "192.168.20.64/26" }
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

