# ipam was set up manually (advanced tier)
# main ipam in usw2 with a pool for usw2 locale
data "aws_vpc_ipam_pool" "ipv4_usw2" {
  provider = aws.usw2

  filter {
    name   = "description"
    values = ["ipv4-test-usw2"]
  }
  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
}

data "aws_vpc_ipam_pool" "ipv6_usw2" {
  provider = aws.usw2

  filter {
    name   = "description"
    values = ["ipv6-test-usw2"]
  }
  filter {
    name   = "address-family"
    values = ["ipv6"]
  }
}


locals {
  ipv4_ipam_pool_usw2 = data.aws_vpc_ipam_pool.ipv4_usw2
  ipv6_ipam_pool_usw2 = data.aws_vpc_ipam_pool.ipv6_usw2

  tiered_vpcs_usw2 = [
    {
      name = "app1"
      ipv4 = {
        network_cidr    = "10.0.0.0/18"
        secondary_cidrs = ["10.1.0.0/20"]
        ipam_pool       = local.ipv4_ipam_pool_usw2
        centralized_egress = {
          central = true
        }
      }
      ipv6 = {
        network_cidr    = "2600:1f24:66:c000::/56"
        secondary_cidrs = ["2600:1f24:66:cd00::/56"]
        ipam_pool       = local.ipv6_ipam_pool_usw2
      }
      azs = {
        a = {
          eigw = true
          private_subnets = [
            { name = "haproxy1", cidr = "10.0.21.64/26", ipv6_cidr = "2600:1f24:66:c001::/64", special = true }
          ]
          public_subnets = [
            { name = "random1", cidr = "10.0.19.0/28", ipv6_cidr = "2600:1f24:66:c000::/64", natgw = true }
          ]
        }
        b = {
          eigw = true
          private_subnets = [
            { name = "cluster2", cidr = "10.0.27.0/24", ipv6_cidr = "2600:1f24:66:c003::/64", special = true }
          ]
          public_subnets = [
            { name = "cluster1", cidr = "10.0.28.0/24", ipv6_cidr = "2600:1f24:66:c004::/64", natgw = true }
          ]
          # secondary cidr
          isolated_subnets = [
            { name = "db1", cidr = "10.1.1.0/24", ipv6_cidr = "2600:1f24:66:c002::/64" }
          ]
        }
        c = {
          eigw = true
          # ipv6 secondary cidr
          private_subnets = [
            { name = "random2", cidr = "10.0.30.0/28", ipv6_cidr = "2600:1f24:66:cd00::/60", special = true },
          ]
          public_subnets = [
            { name = "haproxy2", cidr = "10.0.31.0/26", ipv6_cidr = "2600:1f24:66:c006::/64", natgw = true }
          ]
        }
      }
    },
    {
      name = "general1"
      ipv4 = {
        network_cidr = "192.168.0.0/18"
        ipam_pool    = local.ipv4_ipam_pool_usw2
        centralized_egress = {
          private = true
        }
      }
      ipv6 = {
        network_cidr = "2600:1f24:66:c100::/56"
        ipam_pool    = local.ipv6_ipam_pool_usw2
      }
      azs = {
        a = {
          eigw = true
          private_subnets = [
            { name = "experiment1", cidr = "192.168.0.0/24", ipv6_cidr = "2600:1f24:66:c100::/64", special = true }
          ]
        }
        b = {
          eigw = true
          private_subnets = [
            { name = "cluster2", cidr = "192.168.1.0/24", ipv6_cidr = "2600:1f24:66:c101::/64", special = true }
          ]
        }
        c = {
          eigw = true
          private_subnets = [
            { name = "random2", cidr = "192.168.2.0/28", ipv6_cidr = "2600:1f24:66:c102::/64", special = true },
          ]
        }
      }
    }
  ]
}

module "vpcs_usw2" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.7"

  providers = {
    aws = aws.usw2
  }

  for_each = { for t in local.tiered_vpcs_usw2 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

# Another
locals {
  tiered_vpcs_another_usw2 = [
    {
      name = "cicd1"
      ipv4 = {
        network_cidr = "172.16.0.0/18"
        ipam_pool    = local.ipv4_ipam_pool_usw2
        centralized_egress = {
          central = true
        }
      }
      ipv6 = {
        network_cidr = "2600:1f24:66:c200::/56"
        ipam_pool    = local.ipv6_ipam_pool_usw2
      }
      azs = {
        a = {
          private_subnets = [
            { name = "jenkins1", cidr = "172.16.1.0/24", ipv6_cidr = "2600:1f24:66:c200::/64", special = true }
          ]
          public_subnets = [
            { name = "various1", cidr = "172.16.5.0/28", ipv6_cidr = "2600:1f24:66:c202::/64", natgw = true }
          ]
        }
        b = {
          private_subnets = [
            { name = "jenkins2", cidr = "172.16.7.0/24", ipv6_cidr = "2600:1f24:66:c201::/64", special = true }
          ]
          public_subnets = [
            { name = "various3", cidr = "172.16.9.0/28", ipv6_cidr = "2600:1f24:66:c204::/64", natgw = true }
          ]
        }
        c = {
          private_subnets = [
            { name = "jenkins3", cidr = "172.16.10.0/24", ipv6_cidr = "2600:1f24:66:c203::/64", special = true }
          ]
          public_subnets = [
            { name = "various4", cidr = "172.16.12.0/28", ipv6_cidr = "2600:1f24:66:c207::/64", natgw = true }
          ]
        }
      }
    },
    {
      name = "infra1"
      ipv4 = {
        network_cidr = "10.2.0.0/18"
        ipam_pool    = local.ipv4_ipam_pool_usw2
        centralized_egress = {
          private = true
        }
      }
      ipv6 = {
        network_cidr = "2600:1f24:66:c600::/56"
        ipam_pool    = local.ipv6_ipam_pool_usw2
      }
      azs = {
        a = {
          private_subnets = [
            { name = "jenkins1", cidr = "10.2.0.0/24", ipv6_cidr = "2600:1f24:66:c600::/64", special = true }
          ]
          public_subnets = [
            { name = "random1", cidr = "10.2.1.0/28", ipv6_cidr = "2600:1f24:66:c601::/64" }
          ]
        }
        b = {
          private_subnets = [
            { name = "jenkins2", cidr = "10.2.3.0/24", ipv6_cidr = "2600:1f24:66:c602::/64", special = true }
          ]
          public_subnets = [
            { name = "random2", cidr = "10.2.4.0/28", ipv6_cidr = "2600:1f24:66:c603::/64" }
          ]
        }
        c = {
          private_subnets = [
            { name = "jenkins3", cidr = "10.2.5.0/24", ipv6_cidr = "2600:1f24:66:c604::/64", special = true }
          ]
          public_subnets = [
            { name = "random4", cidr = "10.2.6.0/28", ipv6_cidr = "2600:1f24:66:c605::/64" }
          ]
        }
      }
    }
  ]
}

module "vpcs_another_usw2" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.7"

  providers = {
    aws = aws.usw2
  }

  for_each = { for t in local.tiered_vpcs_another_usw2 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

