locals {
  tiered_vpcs_cac1 = [
    {
      name         = "app7"
      network_cidr = "10.0.96.0/20"
      azs = {
        a = {
          private_subnets = [
            { name = "cluster1", cidr = "10.0.96.0/24" }
          ]
          # Enable a NAT Gateway for all private subnets in the same AZ
          # by adding the `natgw = true` attribute to any public subnet
          public_subnets = [
            { name = "random1", cidr = "10.0.102.0/28", special = true },
            { name = "haproxy1", cidr = "10.0.103.64/26" }
          ]
        }
        b = {
          private_subnets = [
            { name = "cluster2", cidr = "10.0.108.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "10.0.110.0/28", special = true },
            { name = "haproxy2", cidr = "10.0.111.64/26" }
          ]
        }
      }
    },
    {
      name         = "general7"
      network_cidr = "172.16.96.0/20"
      azs = {
        a = {
          private_subnets = [
            { name = "cluster4", cidr = "172.16.96.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "172.16.100.0/28", special = true },
            { name = "haproxy1", cidr = "172.16.102.64/26" }
          ]
        }
        d = {
          private_subnets = [
            { name = "experiment1", cidr = "172.16.108.0/24" }
          ]
          public_subnets = [
            { name = "random3", cidr = "172.16.110.0/28", special = true },
            { name = "haproxy3", cidr = "172.16.111.64/26" }
          ]
        }
      }
    }
  ]
}

module "vpcs_cac1" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.1"

  providers = {
    aws = aws.cac1
  }

  for_each = { for t in local.tiered_vpcs_cac1 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

