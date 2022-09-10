locals {
  vpc_tiers_use1 = [
    {
      azs = {
        a = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
          public  = ["10.0.3.0/24", "10.0.4.0/24"]
        }
        b = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          private = ["10.0.10.0/24", "10.0.11.0/24"]
          public  = ["10.0.12.0/24"]
        }
      }
      name    = "app"
      network = "10.0.0.0/20"
    },
    {
      azs = {
        c = {
          private = ["192.168.10.0/24", "192.168.11.0/24", "192.168.12.0/24"]
          public  = ["192.168.13.0/28"]
        }
      }
      name    = "general"
      network = "192.168.0.0/20"
    }
  ]
}

module "vpcs_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=v1.4.2"

  providers = {
    aws = aws.use1
  }

  for_each = { for t in local.vpc_tiers_use1 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tier             = each.value
}

# This TGW Centralized router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# generate and add routes in each VPC to all other networks.
module "tgw_centralized_router_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=v1.4.2"

  providers = {
    aws = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  amazon_side_asn  = 64519
  vpcs             = module.vpcs_use1
}

# Another
locals {
  vpc_tiers_use1_another = [
    {
      azs = {
        a = {
          private = ["10.0.32.0/24", "10.0.34.0/24"]
          public  = ["10.0.35.0/24", "10.0.36.0/24"]
        }
      }
      name    = "cicd"
      network = "10.0.32.0/20"
    },
    {
      azs = {
        c = {
          private = ["192.168.32.0/24", "192.168.33.0/24", "192.168.34.0/24"]
          public  = ["192.168.35.0/28"]
        }
      }
      name    = "infra"
      network = "192.168.32.0/20"
    }
  ]
}

module "vpcs_use1_another" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=v1.4.2"

  providers = {
    aws = aws.use1
  }

  for_each = { for t in local.vpc_tiers_use1_another : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tier             = each.value
}

# This TGW Centralized router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# generate and add routes in each VPC to all other networks.
module "tgw_centralized_router_use1_another" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=v1.4.2"

  providers = {
    aws = aws.use1
  }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  amazon_side_asn  = 64524
  vpcs             = module.vpcs_use1_another
}
