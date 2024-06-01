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
        }
        b = {
          private_subnets = [
            { name = "cluster2", cidr = "10.0.10.0/24" },
            { name = "random2", cidr = "10.0.11.0/24" }
          ]
          # Enable a NAT Gateway for all private subnets in the same AZ
          # by adding the `natgw = true` attribute to any public subnet
          public_subnets = [
            { name = "random3", cidr = "10.0.12.0/24", special = true }
          ]
        }
      }
    },
    {
      name         = "general2"
      network_cidr = "192.168.0.0/20"
      azs = {
        c = {
          private_subnets = [
            { name = "experiment1", cidr = "192.168.10.0/24", special = true },
            { name = "experiment2", cidr = "192.168.11.0/24" }
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


# Another
locals {
  tiered_vpcs_another_use1 = [
    {
      name         = "cicd2"
      network_cidr = "10.0.32.0/20"
      azs = {
        a = {
          private_subnets = [
            { name = "jenkins1", cidr = "10.0.32.0/24", special = true }
          ]
        }
      }
    },
    {
      name         = "infra2"
      network_cidr = "192.168.32.0/20"
      azs = {
        c = {
          private_subnets = [
            { name = "db1", cidr = "192.168.32.0/24", special = true }
          ]
        }
      }
    }
  ]
}

module "vpcs_another_use1" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.1"

  providers = {
    aws = aws.use1
  }

  for_each = { for t in local.tiered_vpcs_another_use1 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

