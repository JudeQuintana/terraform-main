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
      name = "app3"
      ipv4 = {
        network_cidr    = "10.0.64.0/18"
        secondary_cidrs = ["10.1.64.0/20"]
        ipam_pool       = local.ipv4_ipam_pool_use1
        centralized_egress = {
          private = true
        }
      }
      ipv6 = {
        network_cidr = "2600:1f28:3d:c000::/56"
        ipam_pool    = local.ipv6_ipam_pool_use1
      }
      azs = {
        a = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "cluster1", cidr = "10.0.64.0/24", ipv6_cidr = "2600:1f28:3d:c000::/64" }
          ]
          # Enable a NAT Gateway for all private subnets in the same AZ
          # by adding the "natgw = true" attribute to any public subnet
          public_subnets = [
            { name = "random1", cidr = "10.0.66.0/28", ipv6_cidr = "2600:1f28:3d:c001::/64", special = true },
            { name = "haproxy1", cidr = "10.0.67.64/26", ipv6_cidr = "2600:1f28:3d:c002::/64" }
          ]
        }
        b = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "cluster2", cidr = "10.0.70.0/24", ipv6_cidr = "2600:1f28:3d:c003::/64" }
          ]
          public_subnets = [
            { name = "random2", cidr = "10.0.72.0/28", ipv6_cidr = "2600:1f28:3d:c004::/64", special = true },
            { name = "haproxy2", cidr = "10.0.73.64/26", ipv6_cidr = "2600:1f28:3d:c005::/64" },
            #secondary subnet
            { name = "other1", cidr = "10.1.64.0/24", ipv6_cidr = "2600:1f28:3d:c006::/64" }
          ]
        }
      }
    },
    {
      name = "infra3"
      ipv4 = {
        network_cidr    = "172.18.0.0/18"
        secondary_cidrs = ["172.18.64.0/20"]
        ipam_pool       = local.ipv4_ipam_pool_use1
        centralized_egress = {
          private = true
        }
      }
      ipv6 = {
        network_cidr    = "2600:1f28:3d:c700::/56"
        secondary_cidrs = ["2600:1f28:3d:c800::/56"]
        ipam_pool       = local.ipv6_ipam_pool_use1
      }
      azs = {
        a = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "haproxy5", cidr = "172.18.0.0/24", ipv6_cidr = "2600:1f28:3d:c700::/64" }
          ]
          public_subnets = [
            { name = "edge3", cidr = "172.18.3.0/24", ipv6_cidr = "2600:1f28:3d:c703::/64" },
            { name = "edge4", cidr = "172.18.4.0/24", ipv6_cidr = "2600:1f28:3d:c705::/64", special = true }
          ]
          isolated_subnets = [
            # ipv6 secondary cidr
            { name = "db11", cidr = "172.18.9.0/24", ipv6_cidr = "2600:1f28:3d:c880::/60" }
          ]
        }
        b = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "util4", cidr = "172.18.12.0/24", ipv6_cidr = "2600:1f28:3d:c708::/64" },
            { name = "util5", cidr = "172.18.15.0/24", ipv6_cidr = "2600:1f28:3d:c70a::/64", special = true }
          ]
          isolated_subnets = [
            # secondary cidr
            { name = "db12", cidr = "172.18.67.0/24", ipv6_cidr = "2600:1f28:3d:c70c::/64" }
          ]
        }
      }
    },
    {
      name = "general3"
      ipv4 = {
        network_cidr    = "192.168.64.0/18"
        secondary_cidrs = ["192.168.128.0/20"]
        ipam_pool       = local.ipv4_ipam_pool_use1
        centralized_egress = {
          central = true
        }
      }
      ipv6 = {
        network_cidr = "2600:1f28:3d:c400::/56"
        ipam_pool    = local.ipv6_ipam_pool_use1
      }
      azs = {
        a = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "cluster4", cidr = "192.168.65.0/24", ipv6_cidr = "2600:1f28:3d:c400::/64", special = true }
          ]
          public_subnets = [
            { name = "random2", cidr = "192.168.67.0/28", ipv6_cidr = "2600:1f28:3d:c401::/64", },
            { name = "haproxy1", cidr = "192.168.68.64/26", ipv6_cidr = "2600:1f28:3d:c402::/64", natgw = true }
          ]
        }
        b = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "experiment1", cidr = "192.168.70.0/24", ipv6_cidr = "2600:1f28:3d:c403::/64", special = true }
          ]
          public_subnets = [
            { name = "random3", cidr = "192.168.71.0/28", ipv6_cidr = "2600:1f28:3d:c404::/64", natgw = true },
            { name = "haproxy3", cidr = "192.168.72.64/26", ipv6_cidr = "2600:1f28:3d:c405::/64" },
            # secondary subnet
            { name = "haproxy2", cidr = "192.168.128.0/24", ipv6_cidr = "2600:1f28:3d:c406::/64" }
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

output "vpcs_use1_natgw_eips_per_az" {
  value = { for v in module.vpcs_use1 : v.name => v.public_natgw_az_to_eip }
}

