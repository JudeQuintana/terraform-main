locals {
  tiered_vpcs_use1 = [
    {
      name         = "app2"
      network_cidr = "10.0.0.0/20"
      azs = {
        a = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private_subnets = [
            { name = "cluster1", cidr = "10.0.0.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "10.0.3.0/28", special = true },
            { name = "haproxy1", cidr = "10.0.4.64/26" }
          ]
        }
        b = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private_subnets = [
            { name = "cluster2", cidr = "10.0.10.0/24" },
            { name = "random2", cidr = "10.0.11.0/24" }
          ]
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
            { name = "experiment1", cidr = "192.168.10.0/24" },
            { name = "experiment2", cidr = "192.168.11.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "192.168.13.0/28", special = true },
            { name = "haproxy1", cidr = "192.168.14.64/26" }
          ]
        }
      }
    }
  ]
}

module "vpcs_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=v1.4.8"

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
            { name = "jenkins1", cidr = "10.0.32.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "10.0.36.64/26" },
            { name = "natgw", cidr = "10.0.35.0/28", special = true }
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
            { name = "db1", cidr = "192.168.32.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "192.168.35.0/26", special = true }
          ]
        }
      }
    }
  ]
}

module "vpcs_another_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=v1.4.8"

  providers = {
    aws = aws.use1
  }

  for_each = { for t in local.tiered_vpcs_another_use1 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

