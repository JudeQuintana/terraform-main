# Another
locals {
  tiered_vpcs_use2 = [
    {
      name         = "cicd1"
      network_cidr = "172.16.0.0/20"
      azs = {
        a = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private_subnets = [
            { name = "jenkins1", cidr = "172.16.1.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "172.16.6.0/26" },
            { name = "natgw", cidr = "172.16.5.0/28", special = true }
          ]
        }
      }
    },
    {
      name         = "infra1"
      network_cidr = "172.16.16.0/20"
      azs = {
        c = {
          private_subnets = [
            { name = "jenkins2", cidr = "172.16.16.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "172.16.19.0/28", special = true }
          ]
        }
      }
    }
  ]
}

module "vpcs_use2" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.0"

  providers = {
    aws = aws.use2
  }

  for_each = { for t in local.tiered_vpcs_use2 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

