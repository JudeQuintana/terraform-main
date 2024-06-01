locals {
  tiered_vpcs_use1 = [
    {
      name         = "app2"
      network_cidr = "10.0.0.0/20"
      azs = {
        a = {
          private_subnets = [
            { name = "cluster1", cidr = "10.0.0.0/24", special = true }
          ]
          # Enable a NAT Gateway for all private subnets in the same AZ
          # by adding the `natgw = true` attribute to any public subnet
          public_subnets = [
            { name = "random1", cidr = "10.0.3.0/28" },
            { name = "haproxy1", cidr = "10.0.4.64/26" }
          ]
        }
        b = {
          private_subnets = [
            { name = "cluster2", cidr = "10.0.10.0/24", special = true },
            { name = "random2", cidr = "10.0.11.0/24" }
          ]
          public_subnets = [
            { name = "random3", cidr = "10.0.12.0/24" }
          ]
        }
      }
    },
    {
      name         = "general2"
      network_cidr = "192.168.0.0/20"
      azs = {
        a = {
          private_subnets = [
            { name = "data1", cidr = "192.168.0.0/24" },
            { name = "data2", cidr = "192.168.1.0/24" }
          ]
          public_subnets = [
            { name = "random4", cidr = "192.168.5.0/28", special = true },
            { name = "haproxy4", cidr = "192.168.6.64/26" }
          ]
        }
        c = {
          private_subnets = [
            { name = "experiment1", cidr = "192.168.10.0/24" },
            { name = "experiment2", cidr = "192.168.11.0/24", special = true }
          ]
          public_subnets = [
            { name = "random1", cidr = "192.168.13.0/28" },
            { name = "haproxy1", cidr = "192.168.14.64/26" }
          ]
        }
      }
    }
  ]
}

module "vpcs_use1" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.1"

  providers = {
    aws = aws.use1
  }

  for_each = { for t in local.tiered_vpcs_use1 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}
