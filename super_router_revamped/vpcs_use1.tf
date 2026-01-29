# ipam was set up manually (advanced tier)
# main ipam in usw2 with a pool for use1 locale
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

data "aws_vpc_ipam_pool" "ipv6_use1" {
  provider = aws.use1

  filter {
    name   = "description"
    values = ["ipv6-test-use1"]
  }
  filter {
    name   = "address-family"
    values = ["ipv6"]
  }
}

locals {
  ipv4_ipam_pool_use1 = data.aws_vpc_ipam_pool.ipv4_use1
  ipv6_ipam_pool_use1 = data.aws_vpc_ipam_pool.ipv6_use1

  tiered_vpcs_use1 = [
    {
      name = "app2"
      ipv4 = {
        network_cidr = "10.0.64.0/20"
        ipam_pool    = local.ipv4_ipam_pool_use1
        centralized_egress = {
          central = true
        }
      }
      ipv6 = {
        network_cidr = "2600:1f28:3d:c000::/56"
        ipam_pool    = local.ipv6_ipam_pool_use1
      }
      azs = {
        a = {
          eigw = true
          private_subnets = [
            { name = "cluster2", cidr = "10.0.69.0/24", ipv6_cidr = "2600:1f28:3d:c007::/64", special = true },
          ]
          public_subnets = [
            { name = "natgw1", cidr = "10.0.64.0/24", ipv6_cidr = "2600:1f28:3d:c000::/64", natgw = true }
          ]
        }
        b = {
          eigw = true
          private_subnets = [
            { name = "cluster1", cidr = "10.0.65.0/24", ipv6_cidr = "2600:1f28:3d:c004::/64", special = true },
          ]
          public_subnets = [
            { name = "natgw2", cidr = "10.0.68.0/24", ipv6_cidr = "2600:1f28:3d:c00b::/64", natgw = true }
          ]
        }
        c = {
          eigw = true
          private_subnets = [
            { name = "random2", cidr = "10.0.66.0/24", ipv6_cidr = "2600:1f28:3d:c008::/64", special = true }
          ]
          public_subnets = [
            { name = "natgw3", cidr = "10.0.67.0/24", ipv6_cidr = "2600:1f28:3d:c00a::/64", natgw = true }
          ]
        }
      }
    },
    {
      name = "general2"
      ipv4 = {
        network_cidr = "192.168.128.0/20"
        ipam_pool    = local.ipv4_ipam_pool_use1
        centralized_egress = {
          private = true
        }
      }
      ipv6 = {
        network_cidr = "2600:1f28:3d:c400::/56"
        ipam_pool    = local.ipv6_ipam_pool_use1
      }
      azs = {
        a = {
          eigw = true
          private_subnets = [
            { name = "experiment1", cidr = "192.168.129.0/24", ipv6_cidr = "2600:1f28:3d:c401::/64", special = true },
            { name = "experiment2", cidr = "192.168.130.0/24", ipv6_cidr = "2600:1f28:3d:c402::/64" }
          ]
          isolated_subnets = [
            { name = "db5", cidr = "192.168.128.0/24", ipv6_cidr = "2600:1f28:3d:c400::/64" },
          ]
        }
        b = {
          eigw = true
          private_subnets = [
            { name = "experiment13", cidr = "192.168.134.0/24", ipv6_cidr = "2600:1f28:3d:c407::/64", special = true },
          ]
          isolated_subnets = [
            { name = "db6", cidr = "192.168.133.0/24", ipv6_cidr = "2600:1f28:3d:c406::/64" },
          ]
        }
        c = {
          eigw = true
          private_subnets = [
            { name = "experiment14", cidr = "192.168.137.0/24", ipv6_cidr = "2600:1f28:3d:c40a::/64", special = true },
          ]
          isolated_subnets = [
            { name = "db7", cidr = "192.168.135.0/24", ipv6_cidr = "2600:1f28:3d:c409::/64" },
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
        centralized_egress = {
          central = true
        }
      }
      ipv6 = {
        network_cidr = "2600:1f28:3d:c700::/56"
        ipam_pool    = local.ipv6_ipam_pool_use1
      }
      azs = {
        a = {
          eigw = true
          private_subnets = [
            { name = "jenkins1", cidr = "10.1.65.0/24", ipv6_cidr = "2600:1f28:3d:c700::/64", special = true }
          ]
          public_subnets = [
            { name = "natgw1", cidr = "10.1.69.0/24", ipv6_cidr = "2600:1f28:3d:c703::/64", natgw = true },
            { name = "random1", cidr = "10.1.74.0/24", ipv6_cidr = "2600:1f28:3d:c706::/64" }
          ]
        }
        b = {
          eigw = true
          private_subnets = [
            { name = "jenkins2", cidr = "10.1.66.0/24", ipv6_cidr = "2600:1f28:3d:c701::/64", special = true }
          ]
          public_subnets = [
            { name = "natgw2", cidr = "10.1.70.0/24", ipv6_cidr = "2600:1f28:3d:c704::/64", natgw = true }
          ]
        }
        c = {
          eigw = true
          private_subnets = [
            { name = "jenkins3", cidr = "10.1.67.0/24", ipv6_cidr = "2600:1f28:3d:c702::/64", special = true }
          ]
          public_subnets = [
            { name = "natgw3", cidr = "10.1.71.0/24", ipv6_cidr = "2600:1f28:3d:c705::/64", natgw = true }
          ]
        }
      }
    },
    {
      name = "infra2"
      ipv4 = {
        network_cidr = "192.168.64.0/20"
        ipam_pool    = local.ipv4_ipam_pool_use1
        centralized_egress = {
          private = true
        }
      }
      ipv6 = {
        network_cidr = "2600:1f28:3d:c800::/56"
        ipam_pool    = local.ipv6_ipam_pool_use1
      }
      azs = {
        a = {
          eigw = true
          private_subnets = [
            { name = "jenkins1", cidr = "192.168.64.0/24", ipv6_cidr = "2600:1f28:3d:c800::/64", special = true }
          ]
        }
        b = {
          eigw = true
          private_subnets = [
            { name = "jenkins2", cidr = "192.168.66.0/24", ipv6_cidr = "2600:1f28:3d:c801::/64", special = true }
          ]
        }
        c = {
          eigw = true
          private_subnets = [
            { name = "jenkins3", cidr = "192.168.67.0/24", ipv6_cidr = "2600:1f28:3d:c802::/64", special = true }
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

