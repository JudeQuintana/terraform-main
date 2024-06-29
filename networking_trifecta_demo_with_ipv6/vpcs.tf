# manually set up ipam
data "aws_vpc_ipam_pool" "ipv6" {
  filter {
    name   = "description"
    values = ["ipv6"]
  }
}

locals {
  ipam_pool_id = data.aws_vpc_ipam_pool.ipv6.id
}

locals {
  tiered_vpcs = [
    {
      name         = "app"
      network_cidr = "10.0.0.0/20"
      ipv6 = {
        network_cidr = "2600:1f24:66:c100::/56"
        ipam_pool_id = local.ipam_pool_id
      }
      azs = {
        a = {
          public_subnets = [
            { name = "random1", cidr = "10.0.3.0/28", ipv6_cidr = "2600:1f24:66:c100::/64" },
            { name = "haproxy1", cidr = "10.0.4.0/26", ipv6_cidr = "2600:1f24:66:c101::/64" },
            { name = "other", cidr = "10.0.10.0/28", ipv6_cidr = "2600:1f24:66:c102::/64", special = true }
          ]
          eigw = true
          private_subnets = [
            { name = "another", cidr = "10.0.9.0/24", ipv6_cidr = "2600:1f24:66:c108::/64" },
          ]
        }
        b = {
          eigw = true
          private_subnets = [
            { name = "cluster2", cidr = "10.0.1.0/24", ipv6_cidr = "2600:1f24:66:c106::/64"
            },
            { name = "random2", cidr = "10.0.5.0/24", ipv6_cidr = "2600:1f24:66:c107::/64", special = true }
          ]
        }
      }
    },
    {
      name         = "cicd"
      network_cidr = "172.16.0.0/20"
      ipv6 = {
        network_cidr = "2600:1f24:66:c200::/56"
        ipam_pool_id = local.ipam_pool_id
      }
      azs = {
        b = {
          eigw = true
          private_subnets = [
            { name = "jenkins1", cidr = "172.16.5.0/24", ipv6_cidr = "2600:1f24:66:c200::/64" }
          ]
          # Enable a NAT Gateway for all private subnets in the same AZ
          # by adding the `natgw = true` attribute to any public subnet
          # `special` and `natgw` can also be enabled together on a public subnet
          public_subnets = [
            { name = "other", cidr = "172.16.8.0/28", ipv6_cidr = "2600:1f24:66:c207::/64", special = true },
            #{ name      = "natgw", cidr = "172.16.8.16/28", natgw    = true }
          ]
        }
      }
    },
    {
      name         = "general"
      network_cidr = "192.168.0.0/20"
      ipv6 = {
        network_cidr = "2600:1f24:66:c300::/56"
        ipam_pool_id = local.ipam_pool_id
      }
      azs = {
        c = {
          private_subnets = [
            { name = "db1", cidr = "192.168.10.0/24", ipv6_cidr = "2600:1f24:66:c300::/64", special = true }
          ]
          public_subnets = [
            { name = "other2", cidr = "192.168.14.0/28", ipv6_cidr = "2600:1f24:66:c308::/64" },
            #{ name = "other3", cidr = "192.168.15.0/28", ipv6_cidr = "2600:1f24:66:c309::/64" },
          ]
        }
      }
    }
  ]
}

module "vpcs" {
  #source  = "JudeQuintana/tiered-vpc-ng/aws"
  #version = "1.0.1"
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=ipv6-for-tiered-vpc-ng"

  for_each = { for t in local.tiered_vpcs : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

