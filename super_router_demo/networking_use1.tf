locals {
  tiered_vpcs_use1 = [
    {
      name         = "app"
      network_cidr = "10.0.0.0/20"
      azs = {
        a = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          #private = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
          #public  = ["10.0.3.0/24", "10.0.4.0/24"]
          private_subnets = [
            { name = "cluster1", cidr = "10.0.0.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "10.0.3.0/28" },
            { name = "haproxy1", cidr = "10.0.4.64/26" }
          ]
        }
        b = {
          # Enable a NAT Gateway for all private subnets in the AZ with:
          # enable_natgw = true
          # When enabled, the NAT Gateway will be built in the first public subnet in the list for an AZ by default
          # And when a VPC is passed to a Centralized Router, the VPC attachment will also use the first public subnet in the list by default
          # This is becuase a public subnet will always exist in a Tiered VPC
          # The trade off is always having to assign at least 1 public subnet per AZ so better to make is small public subnet /28 as the first subnet or bigger if you want
          #private = ["10.0.10.0/24", "10.0.11.0/24"]
          #public  = ["10.0.12.0/24"]
          private_subnets = [
            { name = "cluster2", cidr = "10.0.10.0/24" },
            { name = "random2", cidr = "10.0.11.0/24" }
          ]
          public_subnets = [
            { name = "random3", cidr = "10.0.12.0/24" }
          ]
        }
      }
    },
    {
      name         = "general"
      network_cidr = "192.168.0.0/20"
      azs = {
        c = {
          #private = ["192.168.10.0/24", "192.168.11.0/24", "192.168.12.0/24"]
          #public  = ["192.168.13.0/28"]
          private_subnets = [
            { name = "experiement1", cidr = "192.168.10.0/24" },
            { name = "experiement2", cidr = "192.168.11.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "192.168.13.0/28" },
            { name = "haproxy1", cidr = "192.168.14.64/26" }
          ]
        }
      }
    }
  ]
}

module "vpcs_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=moar-better"

  providers = {
    aws = aws.use1
  }

  for_each = { for t in local.tiered_vpcs_use1 : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}


# Another
locals {
  tiered_vpcs_use1_another = [
    {
      name         = "cicd"
      network_cidr = "10.0.32.0/20"
      azs = {
        a = {
          #private = ["10.0.32.0/24", "10.0.34.0/24"]
          #public  = ["10.0.35.0/24", "10.0.36.0/24"]
          private_subnets = [
            { name = "jenkins1", cidr = "10.0.32.0/24" }
          ]
          public_subnets = [
            { name = "natgw", cidr = "10.0.35.0/28" },
            { name = "random1", cidr = "10.0.36.64/26" }
          ]
        }
      }
    },
    {
      name         = "infra"
      network_cidr = "192.168.32.0/20"
      azs = {
        c = {
          #private = ["192.168.32.0/24", "192.168.33.0/24", "192.168.34.0/24"]
          #public  = ["192.168.35.0/28"]
          private_subnets = [
            { name = "db1", cidr = "192.168.32.0/24" }
          ]
          public_subnets = [
            { name = "random1", cidr = "192.168.35.0/26" }
          ]
        }
      }
    }
  ]
}

module "vpcs_use1_another" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/tiered_vpc_ng?ref=moar-better"

  providers = {
    aws = aws.use1
  }

  for_each = { for t in local.tiered_vpcs_use1_another : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tiered_vpc       = each.value
}

locals {
  centralized_routers_use1 = [
    {
      name            = "wolverine"
      amazon_side_asn = 64519
      vpcs            = module.vpcs_use1
    },
    {
      name            = "bishop"
      amazon_side_asn = 64524
      vpcs            = module.vpcs_use1_another
    }
  ]
}

# This TGW Centralized router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# generate and add routes in each VPC to all other networks.
module "centralized_routers_use1" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/transit_gateway_centralized_router_for_tiered_vpc_ng?ref=moar-better"

  providers = {
    aws = aws.use1
  }

  for_each = { for c in local.centralized_routers_use1 : c.name => c }

  env_prefix         = var.env_prefix
  region_az_labels   = var.region_az_labels
  centralized_router = each.value
}
