locals {
  tiered_vpcs_euw1 = [
    {
      name         = "app4"
      network_cidr = "10.0.32.0/20"
      azs = {
        a = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private_subnets = [
            { name = "cluster1", cidr = "10.0.32.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "10.0.38.0/28", special = true },
          ]
        }
        b = {
          private_subnets = [
            { name = "cluster2", cidr = "10.0.42.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "10.0.46.0/28", special = true },
          ]
        }
      }
    },
    {
      name         = "general4"
      network_cidr = "192.168.32.0/20"
      azs = {
        a = {
          private_subnets = [
            { name = "cluster4", cidr = "192.168.32.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "192.168.35.0/28", special = true },
          ]
        }
        c = {
          private_subnets = [
            { name = "experiment1", cidr = "192.168.38.0/24" }
          ]
          public_subnets = [
            { name = "random3", cidr = "192.168.40.0/28", special = true },
          ]
        }
      }
    }
  ]
}

module "vpcs_euw1" {
  source = "git@github.com:JudeQuintana/terraform-aws-tiered-vpc-ng.git?ref=v1.0.0"

  providers = {
    aws = aws.euw1
  }

  for_each = { for t in local.tiered_vpcs_euw1 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

