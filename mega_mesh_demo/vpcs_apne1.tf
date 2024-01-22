# apne1 only ap-northeast-1a, ap-northeast-1c, ap-northeast-1d azs are available
locals {
  tiered_vpcs_apne1 = [
    {
      name         = "app5"
      network_cidr = "172.16.32.0/20"
      azs = {
        a = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private_subnets = [
            { name = "cluster1", cidr = "172.16.32.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "172.16.34.0/28", special = true },
          ]
        }
        c = {
          private_subnets = [
            { name = "cluster2", cidr = "172.16.40.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "172.16.45.0/28", special = true },
          ]
        }
      }
    },
    {
      name         = "general5"
      network_cidr = "172.16.64.0/20"
      azs = {
        a = {
          private_subnets = [
            { name = "cluster4", cidr = "172.16.64.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "172.16.70.0/28", special = true },
          ]
        }
        c = {
          private_subnets = [
            { name = "experiment1", cidr = "172.16.73.0/28" }
          ]
          public_subnets = [
            { name = "random3", cidr = "172.16.75.0/28", special = true },
          ]
        }
      }
    }
  ]
}

module "vpcs_apne1" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.0"

  providers = {
    aws = aws.apne1
  }

  for_each = { for t in local.tiered_vpcs_apne1 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

