# ipam was set up manually (advanced tier)
# main ipam in use1 with a pool for usw2 locale
data "aws_vpc_ipam_pool" "ipv4_use1" {
  provider = aws.use1

  filter {
    name   = "description"
    values = ["ipv4-test-use1"]
  }
  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
}

locals {
  ipv4_ipam_pool_use1 = data.aws_vpc_ipam_pool.ipv4_use1

  tiered_vpcs_use1 = [
    {
      name = "app2"
      ipv4 = {
        network_cidr = "10.0.64.0/20"
        ipam_pool    = local.ipv4_ipam_pool_use1
        #centralized_egress = {
        #central = true
        #}
      }
      azs = {
        a = {
          private_subnets = [
            { name = "cluster1", cidr = "10.0.64.0/24", special = true }
          ]
        }
        b = {
          private_subnets = [
            { name = "cluster2", cidr = "10.0.65.0/24" },
            { name = "random2", cidr = "10.0.66.0/24" }
          ]
          # Enable a NAT Gateway for all private subnets in the same AZ
          # by adding the `natgw = true` attribute to any public subnet
          public_subnets = [
            { name = "random3", cidr = "10.0.67.0/24", special = true }
          ]
        }
      }
    },
    {
      name = "general2"
      ipv4 = {
        network_cidr = "192.168.128.0/20"
        ipam_pool    = local.ipv4_ipam_pool_use1
        #centralized_egress = {
        #private = true
        #}
      }
      azs = {
        c = {
          private_subnets = [
            { name = "experiment1", cidr = "192.168.128.0/24", special = true },
            { name = "experiment2", cidr = "192.168.129.0/24" }
          ]
        }
      }
    }
  ]
}

module "vpcs_use1" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.7"

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
      name = "cicd2"
      ipv4 = {
        network_cidr = "10.1.64.0/20"
        ipam_pool    = local.ipv4_ipam_pool_use1
        #centralized_egress = {
        #central = true
        #}
      }
      azs = {
        a = {
          private_subnets = [
            { name = "jenkins1", cidr = "10.1.65.0/24", special = true }
          ]
        }
      }
    },
    {
      name = "infra2"
      ipv4 = {
        network_cidr = "192.168.64.0/20"
        ipam_pool    = local.ipv4_ipam_pool_use1
        #centralized_egress = {
        #private = true
        #}
      }
      azs = {
        c = {
          private_subnets = [
            { name = "db1", cidr = "192.168.64.0/24", special = true }
          ]
        }
      }
    }
  ]
}

module "vpcs_another_use1" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.7"

  providers = {
    aws = aws.use1
  }

  for_each = { for t in local.tiered_vpcs_another_use1 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

