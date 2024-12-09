# ipam was set up manually (advanced tier)
data "aws_vpc_ipam_pool" "ipv4" {
  filter {
    name   = "description"
    values = ["ipv4-test-usw2"]
  }
  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
}

data "aws_vpc_ipam_pool" "ipv6" {
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
  ipv4_ipam_pool = data.aws_vpc_ipam_pool.ipv4
  ipv6_ipam_pool = data.aws_vpc_ipam_pool.ipv6

  # vpcs with an ipv4 network cidr /18 provides /20 subnet for each AZ.
  tiered_vpcs = [
    {
      name = "app"
      ipv4 = {
        network_cidr    = "10.0.0.0/18"
        secondary_cidrs = ["10.1.0.0/20"]
        ipam_pool       = local.ipv4_ipam_pool
      }
      ipv6 = {
        network_cidr    = "2600:1f24:66:c000::/56"
        secondary_cidrs = ["2600:1f24:66:c800::/56"]
        ipam_pool       = local.ipv6_ipam_pool
      }
      azs = {
        a = {
          isolated_subnets = [
            # secondary cidr
            { name = "hidden1", cidr = "10.1.13.0/24", ipv6_cidr = "2600:1f24:66:c850::/60" }
          ]
          #eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "another", cidr = "10.0.9.0/24", ipv6_cidr = "2600:1f24:66:c008::/64" },
            # secondary ipv6 cidr
            { name = "another2", cidr = "10.0.14.0/24", ipv6_cidr = "2600:1f24:66:c810::/60" },
            # secondary cidr  and secondary ipv6 cidr
            { name = "another3", cidr = "10.1.15.0/24", ipv6_cidr = "2600:1f24:66:c820::/60" }
          ]
          # Enable a NAT Gateway for all private subnets in the same AZ
          # by adding the "natgw = true" attribute to any public subnet
          # "special" and "natgw" can also be enabled together on a public subnet
          public_subnets = [
            { name = "random1", cidr = "10.0.3.0/28", ipv6_cidr = "2600:1f24:66:c000::/64" },
            { name = "haproxy1", cidr = "10.0.4.0/26", ipv6_cidr = "2600:1f24:66:c001::/64" },
            { name = "other", cidr = "10.0.10.0/28", ipv6_cidr = "2600:1f24:66:c002::/64", special = true }
          ]
        }
        b = {
          #eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "cluster2", cidr = "10.0.16.0/24", ipv6_cidr = "2600:1f24:66:c006::/64" },
            { name = "random2", cidr = "10.0.17.0/24", ipv6_cidr = "2600:1f24:66:c007::/64" },
            # special can be assigned to a secondary cidr subnet and be used as a vpc attachemnt when passed to centralized router
            { name = "random3", cidr = "10.1.5.0/24", ipv6_cidr = "2600:1f24:66:c009::/64", special = true }
          ]
        }
      }
    },
    {
      name = "general"
      ipv4 = {
        network_cidr = "192.168.0.0/18"
        ipam_pool    = local.ipv4_ipam_pool
      }
      ipv6 = {
        network_cidr = "2600:1f24:66:c100::/56"
        ipam_pool    = local.ipv6_ipam_pool
      }
      azs = {
        c = {
          #eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "db1", cidr = "192.168.10.0/24", ipv6_cidr = "2600:1f24:66:c100::/64", special = true },
            { name = "db2", cidr = "192.168.11.0/24", ipv6_cidr = "2600:1f24:66:c101::/64" }
          ]
          public_subnets = [
            { name = "other2", cidr = "192.168.14.0/28", ipv6_cidr = "2600:1f24:66:c108::/64" }
          ]
        }
      }
    },
    {
      name = "cicd"
      ipv4 = {
        network_cidr    = "172.16.0.0/18"
        secondary_cidrs = ["172.19.0.0/20"] # aws recommends not using 172.17.0.0/16
        ipam_pool       = local.ipv4_ipam_pool
      }
      ipv6 = {
        network_cidr    = "2600:1f24:66:c200::/56"
        secondary_cidrs = ["2600:1f24:66:c600::/56"]
        ipam_pool       = local.ipv6_ipam_pool
      }
      azs = {
        b = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "jenkins1", cidr = "172.16.5.0/24", ipv6_cidr = "2600:1f24:66:c200::/64" },
            { name = "experiment1", cidr = "172.19.5.0/24", ipv6_cidr = "2600:1f24:66:c202::/64" },
            # secondary ipv6 cidr
            { name = "experiment2", cidr = "172.19.9.0/24", ipv6_cidr = "2600:1f24:66:c602::/64" }
          ]
          public_subnets = [
            { name = "other", cidr = "172.16.8.0/28", ipv6_cidr = "2600:1f24:66:c207::/64", special = true },
            # build natgw in public subnet for private ipv4 subnets to route out igw per az
            { name = "natgw", cidr = "172.16.16.16/28", ipv6_cidr = "2600:1f24:66:c208::/64", natgw = true }
          ]
        }
      }
    }
  ]
}

module "vpcs" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.4"

  for_each = { for t in local.tiered_vpcs : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

