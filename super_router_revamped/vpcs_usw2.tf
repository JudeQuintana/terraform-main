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

locals {
  ipv4_ipam_pool_usw2 = data.aws_vpc_ipam_pool.ipv4_usw2

  tiered_vpcs_usw2 = [
    {
      name = "app1"
      ipv4 = {
        network_cidr = "10.0.0.0/18"
        #secondary_cidrs = ["10.1.0.0/20"]
        ipam_pool = local.ipv4_ipam_pool_usw2
        #centralized_egress = {
        #central = true
        #}
      }
      azs = {
        a = {
          public_subnets = [
            { name = "random1", cidr = "10.0.19.0/28", special = true },
            { name = "haproxy1", cidr = "10.0.21.64/26" }
          ]
        }
        b = {
          # secondary cidr
          #isolated_subnets = [
          #{ name = "db1", cidr = "10.1.1.0/24" }
          #]
          private_subnets = [
            { name = "cluster2", cidr = "10.0.27.0/24" }
          ]
          # Enable a NAT Gateway for all private subnets in the same AZ
          # by adding the `natgw = true` attribute to any public subnet
          public_subnets = [
            { name = "random2", cidr = "10.0.30.0/28", special = true },
            { name = "haproxy2", cidr = "10.0.31.64/26" }
          ]
        }
      }
    },
    {
      name = "general1"
      ipv4 = {
        network_cidr = "192.168.0.0/18"
        ipam_pool    = local.ipv4_ipam_pool_usw2
        #centralized_egress = {
        #private = true
        #}
      }
      azs = {
        c = {
          private_subnets = [
            { name = "experiment1", cidr = "192.168.16.0/24", special = true }
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
        #centralized_egress = {
        #central = true
        #}
      }
      azs = {
        a = {
          private_subnets = [
            { name = "jenkins1", cidr = "172.16.1.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "172.16.6.0/26" },
            { name = "various", cidr = "172.16.5.0/28", special = true }
          ]
        }
      }
    },
    {
      name = "infra1"
      ipv4 = {
        network_cidr = "10.2.0.0/18"
        ipam_pool    = local.ipv4_ipam_pool_usw2
        #centralized_egress = {
        #private = true
        #}
      }
      azs = {
        c = {
          private_subnets = [
            { name = "jenkins2", cidr = "10.2.0.0/24", special = true }
          ]
          public_subnets = [
            { name = "random1", cidr = "10.2.1.0/28" }
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

