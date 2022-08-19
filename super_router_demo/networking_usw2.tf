locals {
  vpc_tiers_usw2 = [
    {
      azs = {
        a = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private = ["10.0.16.0/24", "10.0.17.0/24", "10.0.18.0/24"]
          public  = ["10.0.19.0/24", "10.0.20.0/24", "10.0.21.0/24"]
        }
        b = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private = ["10.0.26.0/24"]
          public  = ["10.0.27.0/24"]
        }
      }
      name    = "app"
      network = "10.0.16.0/20"
    },
    {
      azs = {
        c = {
          private = ["192.168.16.0/24", "192.168.17.0/24", "192.168.18.0/24"]
          public  = ["192.168.19.0/28"]
        }
      }
      name    = "general"
      network = "192.168.16.0/20"
    }
  ]
}

module "vpcs_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=v1.4.0"

  providers = {
    aws = aws.usw2
  }

  for_each = { for t in local.vpc_tiers_usw2 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tier             = each.value
}

# This TGW Centralized router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# generate and add routes in each VPC to all other networks.
module "tgw_centralized_router_usw2" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=v1.4.0"

  providers = {
    aws = aws.usw2
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  amazon_side_asn  = 64520
  vpcs             = module.vpcs_usw2
}


# Another
locals {
  vpc_tiers_usw2_another = [
    {
      azs = {
        a = {
          private = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
          public  = ["172.16.5.0/28"]
        }
      }
      name    = "cicd"
      network = "172.16.0.0/20"
    },
    {
      azs = {
        c = {
          private = ["172.16.16.0/24", "172.16.17.0/24", "172.16.18.0/24"]
          public  = ["172.16.19.0/28"]
        }
      }
      name    = "infra"
      network = "172.16.16.0/20"
    }
  ]
}

module "vpcs_usw2_another" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=v1.4.0"

  providers = {
    aws = aws.usw2
  }

  for_each = { for t in local.vpc_tiers_usw2_another : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tier             = each.value
}

# This TGW Centralized router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# generate and add routes in each VPC to all other networks.

# peering between the super router and centralized_routers within the same region and cross region works now (within same account).
module "tgw_centralized_router_usw2_another" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=v1.4.0"

  providers = {
    aws = aws.usw2
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  amazon_side_asn  = 64525
  vpcs             = module.vpcs_usw2_another
}

