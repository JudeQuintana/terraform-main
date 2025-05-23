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
}

# ipv4 and ipv6 must use an ipam pool
# can start with ipv4 only and then add ipv6 later if needed.
# vpcs with an ipv4 network cidr /18 provides /20 subnet for each AZ.
locals {
  tiered_vpcs_usw2 = [
    {
      name = "app2"
      ipv4 = {
        network_cidr    = "10.0.0.0/18"
        secondary_cidrs = ["10.1.0.0/20"]
        ipam_pool       = local.ipv4_ipam_pool_usw2
        centralized_egress = {
          private = true
        }
      }
      ipv6 = {
        network_cidr = "2600:1f24:66:c000::/56"
        ipam_pool    = local.ipv6_ipam_pool_usw2
      }
      azs = {
        a = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "another", cidr = "10.0.9.0/24", ipv6_cidr = "2600:1f24:66:c008::/64" }
          ]
          public_subnets = [
            { name = "random1", cidr = "10.0.3.0/28", ipv6_cidr = "2600:1f24:66:c000::/64" },
            { name = "haproxy1", cidr = "10.0.4.0/26", ipv6_cidr = "2600:1f24:66:c001::/64" },
            { name = "other", cidr = "10.0.10.0/28", ipv6_cidr = "2600:1f24:66:c002::/64", special = true }
          ]
          isolated_subnets = [
            # secondary cidr
            { name = "db1", cidr = "10.1.13.0/24", ipv6_cidr = "2600:1f24:66:c050::/60" }
          ]
        }
        b = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "cluster2", cidr = "10.0.16.0/24", ipv6_cidr = "2600:1f24:66:c006::/64" },
            { name = "random2", cidr = "10.0.17.0/24", ipv6_cidr = "2600:1f24:66:c007::/64", special = true }
          ]
          isolated_subnets = [
            # secondary cidr
            { name = "db2", cidr = "10.1.0.0/24", ipv6_cidr = "2600:1f24:66:c009::/64" }
          ]
        }
      }
    },
    {
      name = "infra2"
      ipv4 = {
        network_cidr    = "10.2.0.0/18"
        secondary_cidrs = ["10.2.64.0/20"]
        ipam_pool       = local.ipv4_ipam_pool_usw2
        centralized_egress = {
          private = true
        }
      }
      ipv6 = {
        network_cidr    = "2600:1f24:66:ca00::/56"
        secondary_cidrs = ["2600:1f24:66:cd00::/56"]
        ipam_pool       = local.ipv6_ipam_pool_usw2
      }
      azs = {
        a = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "util4", cidr = "10.2.0.0/24", ipv6_cidr = "2600:1f24:66:ca00::/64" }
          ]
          public_subnets = [
            { name = "edge1", cidr = "10.2.6.0/24", ipv6_cidr = "2600:1f24:66:ca01::/64" },
            { name = "edge2", cidr = "10.2.7.0/24", ipv6_cidr = "2600:1f24:66:ca02::/64", special = true }
          ]
          isolated_subnets = [
            # ipv6 secondary cidr
            { name = "db4", cidr = "10.2.10.0/28", ipv6_cidr = "2600:1f24:66:cd10::/60" }
          ]
        }
        b = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "ngnix1", cidr = "10.2.9.0/24", ipv6_cidr = "2600:1f24:66:ca1b::/64" },
            { name = "nginx2", cidr = "10.2.11.0/24", ipv6_cidr = "2600:1f24:66:ca1c::/64", special = true }
          ]
          isolated_subnets = [
            # secondary cidr
            { name = "db6", cidr = "10.2.65.0/24", ipv6_cidr = "2600:1f24:66:ca1d::/64" }
          ]
        }
      }
    },
    {
      name = "general2"
      ipv4 = {
        network_cidr    = "192.168.0.0/18"
        secondary_cidrs = ["192.168.144.0/20"]
        ipam_pool       = local.ipv4_ipam_pool_usw2
        centralized_egress = {
          central = true
        }
      }
      ipv6 = {
        network_cidr = "2600:1f24:66:c100::/56"
        ipam_pool    = local.ipv6_ipam_pool_usw2
      }
      azs = {
        a = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "util2", cidr = "192.168.10.0/24", ipv6_cidr = "2600:1f24:66:c100::/64", special = true },
            { name = "util1", cidr = "192.168.11.0/24", ipv6_cidr = "2600:1f24:66:c101::/64" }
          ]
          public_subnets = [
            { name = "other2", cidr = "192.168.14.0/28", ipv6_cidr = "2600:1f24:66:c108::/64", natgw = true }
          ]
        }
        b = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "cluster5", cidr = "192.168.13.0/24", ipv6_cidr = "2600:1f24:66:c102::/64", special = true }
          ]
          public_subnets = [
            # secondary subnet
            { name = "other3", cidr = "192.168.144.0/24", ipv6_cidr = "2600:1f24:66:c109::/64", natgw = true }
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

output "vpcs_usw2_natgw_eips_per_az" {
  value = { for v in module.vpcs_usw2 : v.name => v.public_natgw_az_to_eip }
}

