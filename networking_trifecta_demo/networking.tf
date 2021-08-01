locals {
  vpc_tiers = [
    {
      azs = {
        a = {
          private = ["10.0.8.0/24", "10.0.9.0/24"]
          public  = ["10.0.0.0/28"]
        },
        b = {
          #enable_natgw = true
          private = []
          public  = ["10.0.3.0/24"]
        },
      }
      name    = "app"
      network = "10.0.0.0/20"
    },
    {
      azs = {
        a = {
          #enable_natgw = true
          private = ["172.31.0.0/24", "172.31.1.0/24"]
          public  = ["172.31.5.0/28"] # /24 chopped up into /28
        },
        #b = {
        ##enable_natgw = true
        #private = ["10.0.20.0/24", "10.0.21.0/24"]
        #public  = ["10.0.28.16/28"] # 10.0.28.0/24 chopped up into /28
        #},
      }
      name    = "db"
      network = "172.31.0.0/20"
    },
    {
      azs = {
        #a = {
        #private = ["10.47.11.0/24", "10.47.12.0/24"]
        #public  = ["10.47.0.0/28", "10.47.0.16/28"] # 10.47.0.0/24 chopped up into /28
        #},
        c = {
          #private = []
          private = ["192.168.0.0/24"] #"192.168.1.0/24"
          public  = ["192.168.5.0/24"]
          #public = ["10.47.6.0/24", "10.47.7.0/24"]
        }
      }
      name    = "general"
      network = "192.168.0.0/20"
    }
  ]
}

module "usw2_vpcs" {
  source = "../../yoloform/modules/networking/tiered_vpc_ng"

  for_each = { for t in local.vpc_tiers : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tier             = each.value
}

#output "vpcs" {
#value = module.usw2_vpcs
#}

locals {
  intra_vpc_security_group_rules = [
    {
      label     = "ssh"
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
    },
    {
      label     = "ping"
      from_port = 8
      to_port   = 0
      protocol  = "icmp"
    }
  ]
}

# This will create a sg rule for each vpc allowing inbound-only ports from
# all other vpc networks (excluding itself)
module "intra_vpc_security_group_rules" {
  source = "../../yoloform/modules/networking/intra_vpc_security_group_rules_for_tiered_vpc_ng"

  for_each = { for r in local.intra_vpc_security_group_rules : r.label => r }

  env_prefix = var.env_prefix
  rule       = each.value
  vpcs       = module.usw2_vpcs
}

# This TGW Central router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# add routes in each VPC to all other networks.
module "tgw" {
  source = "../../yoloform/modules/networking/transit_gateway_centralized_router_for_tiered_vpc_ng"

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  vpcs             = module.usw2_vpcs

  # not working
  #depends_on = [module.usw2_vpcs]
}

#output "tgw" {
#value = module.tgw
#}
