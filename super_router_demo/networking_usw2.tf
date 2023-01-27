locals {
  tiered_vpcs_usw2 = [
    {
      name         = "app1"
      network_cidr = "10.0.16.0/20"
      azs = {
        a = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          #private = ["10.0.16.0/24", "10.0.17.0/24", "10.0.18.0/24"]
          #public  = ["10.0.19.0/24", "10.0.20.0/24", "10.0.21.0/24"]
          private_subnets = [
            { name = "cluster1", cidr = "10.0.16.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "10.0.19.0/28", special = true },
            { name = "haproxy1", cidr = "10.0.21.64/26" }
          ]
        }
        b = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          #private = ["10.0.26.0/24"]
          #public  = ["10.0.27.0/24"]
          private_subnets = [
            { name = "cluster2", cidr = "10.0.27.0/24" }
          ]
          public_subnets = [
            { name = "random2", cidr = "10.0.30.0/28", special = true },
            { name = "haproxy2", cidr = "10.0.31.64/26" }
          ]
        }
      }
    },
    {
      name         = "general1"
      network_cidr = "192.168.16.0/20"
      azs = {
        c = {
          #private = ["192.168.16.0/24", "192.168.17.0/24", "192.168.18.0/24"]
          #public  = ["192.168.19.0/28"]
          private_subnets = [
            { name = "experiment1", cidr = "192.168.16.0/24" }
          ]
          public_subnets = [
            { name = "random3", cidr = "192.168.19.0/28", special = true },
            { name = "haproxy3", cidr = "192.168.20.64/26" }
          ]
        }
      }
    }
  ]
}

module "vpcs_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=moar-better"

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
      name         = "cicd1"
      network_cidr = "172.16.0.0/20"
      azs = {
        a = {
          #private = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
          #public  = ["172.16.5.0/28"]
          private_subnets = [
            { name = "jenkins1", cidr = "172.16.1.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "172.16.6.0/26" },
            { name = "natgw", cidr = "172.16.5.0/28", special = true }
          ]
        }
      }
    },
    {
      name         = "infra1"
      network_cidr = "172.16.16.0/20"
      azs = {
        c = {
          #private = ["172.16.16.0/24", "172.16.17.0/24", "172.16.18.0/24"]
          #public  = ["172.16.19.0/28"]
          private_subnets = [
            { name = "jenkins2", cidr = "172.16.16.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "172.16.19.0/28", special = true }
          ]
        }
      }
    }
  ]
}

module "vpcs_another_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=moar-better"

  providers = {
    aws = aws.usw2
  }

  for_each = { for t in local.tiered_vpcs_another_usw2 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

locals {
  centralized_routers_usw2 = [
    {
      name            = "thunderbird"
      amazon_side_asn = 64520
      blackhole_cidrs = local.blackhole_cidrs
      vpcs            = module.vpcs_usw2
    },
    {
      name            = "storm"
      amazon_side_asn = 64525
      blackhole_cidrs = local.blackhole_cidrs
      vpcs            = module.vpcs_another_usw2
    }
  ]
}

module "centralized_routers_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=moar-better"

  providers = {
    aws = aws.usw2
  }

  for_each = { for c in local.centralized_routers_usw2 : c.name => c }

  env_prefix         = var.env_prefix
  region_az_labels   = var.region_az_labels
  centralized_router = each.value
}
