# ipam was set up manually (advanced tier)
# main ipam in usw2 with a pool for use2 locale
data "aws_vpc_ipam_pool" "ipv4_use2" {
  provider = aws.use2

  filter {
    name   = "description"
    values = ["ipv4-test-use2"]
  }
  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
}

data "aws_vpc_ipam_pool" "ipv6_use2" {
  provider = aws.use2

  filter {
    name   = "description"
    values = ["ipv6-test-use2"]
  }
  filter {
    name   = "address-family"
    values = ["ipv6"]
  }
}

locals {
  ipv4_ipam_pool_use2 = data.aws_vpc_ipam_pool.ipv4_use2
  ipv6_ipam_pool_use2 = data.aws_vpc_ipam_pool.ipv6_use2

  tiered_vpcs_use2 = [
    {
      name = "app1"
      ipv4 = {
        network_cidr    = "172.16.64.0/18"
        secondary_cidrs = ["172.16.192.0/20"]
        ipam_pool       = local.ipv4_ipam_pool_use2
        centralized_egress = {
          private = true
        }
      }
      ipv6 = {
        network_cidr    = "2600:1f26:21:c000::/56"
        secondary_cidrs = ["2600:1f26:21:c400::/56"]
        ipam_pool       = local.ipv6_ipam_pool_use2
      }
      azs = {
        a = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "jenkins1", cidr = "172.16.65.0/24", ipv6_cidr = "2600:1f26:21:c001::/64" }
          ]
          public_subnets = [
            { name = "other", cidr = "172.16.68.0/28", ipv6_cidr = "2600:1f26:21:c002::/64", special = true },
            { name = "other2", cidr = "172.16.76.16/28", ipv6_cidr = "2600:1f26:21:c003::/64" },
            # ipv6 secondary cidr
            { name = "test1", cidr = "172.16.77.32/28", ipv6_cidr = "2600:1f26:21:c400::/60" }
          ]
        }
        c = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            # secondary cidr
            { name = "experiment1", cidr = "172.16.192.0/24", ipv6_cidr = "2600:1f26:21:c004::/64", special = true }
          ]
          public_subnets = [
            #ipv4 secondary cidr and  ipv6 secondary cidr
            { name = "test2", cidr = "172.16.194.0/24", ipv6_cidr = "2600:1f26:21:c410::/60" }
          ]
        }
      }
    },
    {
      name = "infra1"
      ipv4 = {
        network_cidr    = ""
        secondary_cidrs = [""]
        ipam_pool       = local.ipv4_ipam_pool_use2
        centralized_egress = {
          private = true
        }
      }
      ipv6 = {
        network_cidr = ""
        ipam_pool    = local.ipv6_ipam_pool_use2
      }
      azs = {
        a = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "", cidr = "", ipv6_cidr = "" }
          ]
          public_subnets = [
            { name = "", cidr = "", ipv6_cidr = "" },
            { name = "", cidr = "", ipv6_cidr = "" },
            { name = "", cidr = "", ipv6_cidr = "", special = true }
          ]
          isolated_subnets = [
            # secondary cidr
            { name = "", cidr = "", ipv6_cidr = "" }
          ]
        }
        b = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "", cidr = "", ipv6_cidr = "" },
            { name = "", cidr = "", ipv6_cidr = "", special = true }
          ]
          isolated_subnets = [
            # secondary cidr
            { name = "", cidr = "", ipv6_cidr = "" }
          ]
        }
      }
    },
    {
      name = "general1"
      ipv4 = {
        network_cidr    = "172.16.128.0/18"
        secondary_cidrs = ["172.16.208.0/20"]
        ipam_pool       = local.ipv4_ipam_pool_use2
        centralized_egress = {
          central = true
        }
      }
      ipv6 = {
        network_cidr = "2600:1f26:21:c100::/56"
        ipam_pool    = local.ipv6_ipam_pool_use2
      }
      azs = {
        a = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "artifacts2", cidr = "172.16.129.0/24", ipv6_cidr = "2600:1f26:21:c101::/64", special = true }
          ]
          public_subnets = [
            { name = "random1", cidr = "172.16.131.0/28", ipv6_cidr = "2600:1f26:21:c102::/64", natgw = true }
          ]
        }
        c = {
          eigw = true # opt-in ipv6 private subnets to route out eigw per az
          private_subnets = [
            { name = "jenkins2", cidr = "172.16.132.0/24", ipv6_cidr = "2600:1f26:21:c103::/64", special = true }
          ]
          public_subnets = [
            { name = "random2", cidr = "172.16.133.0/28", ipv6_cidr = "2600:1f26:21:c104::/64", natgw = true },
            # secondary cidr
            { name = "random3", cidr = "172.16.208.0/24", ipv6_cidr = "2600:1f26:21:c105::/64" }
          ]
        }
      }
    }
  ]
}

module "vpcs_use2" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.7"

  providers = {
    aws = aws.use2
  }

  for_each = { for t in local.tiered_vpcs_use2 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

output "vpcs_use2_natgw_eips_per_az" {
  value = { for v in module.vpcs_use2 : v.name => v.public_natgw_az_to_eip }
}

