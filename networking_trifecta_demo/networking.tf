locals {
  vpc_tiers = [
    {
      azs = {
        a = {
          private = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
          public  = ["10.0.3.0/24", "10.0.4.0/24"]
        }
        b = {
          #enable_natgw = true
          private = ["10.0.5.0/24", "10.0.6.0/24", "10.0.7.0/24"]
          public  = ["10.0.8.0/24", "10.0.9.0/24"]
        }
        c = {
          #enable_natgw = true
          private = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
          public  = ["10.0.13.0/24", "10.0.14.0/24"]
        }
      }
      name    = "app"
      network = "10.0.0.0/20"
    },
    {
      azs = {
        a = {
          #enable_natgw = true
          private = ["172.16.0.0/24", "172.16.1.0/24", "172.16.2.0/24"]
          public  = ["172.16.3.0/28", "172.16.4.0/28"]
        }
        b = {
          #enable_natgw = true
          private = ["172.16.5.0/24", "172.16.6.0/24", "172.16.7.0/24"]
          public  = ["172.16.8.0/28", "172.16.9.0/28"]
        }
        c = {
          #enable_natgw = true
          private = ["172.16.10.0/24", "172.16.11.0/24", "172.16.12.0/24"]
          public  = ["172.16.13.0/28", "172.16.14.0/28"]
        }
      }
      name    = "cicd"
      network = "172.16.0.0/20"
    },
    {
      azs = {
        a = {
          private = ["192.168.0.0/24", "192.168.1.0/24", "192.168.2.0/24"]
          public  = ["192.168.13.0/28"]
        }
        b = {
          private = ["192.168.5.0/24", "192.168.6.0/24", "192.168.7.0/24"]
          public  = ["192.168.8.0/28"]
        }
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

module "vpcs" {
  source = "../../yoloform/modules/networking/tiered_vpc_ng"

  for_each = { for t in local.vpc_tiers : t.name => t }

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  tier             = each.value
}

#output "vpcs" {
#value = module.vpcs
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
  source = "../../yoloform/modules/networking/intra_vpc_security_group_rule_for_tiered_vpc_ng"

  for_each = { for r in local.intra_vpc_security_group_rules : r.label => r }

  env_prefix = var.env_prefix
  vpcs       = module.vpcs
  rule       = each.value
}

# This TGW Central router module will attach all vpcs (attachment for each AZ) to one TGW
# associate and propagate to a single route table
# add routes in each VPC to all other networks.
module "tgw_centralized_router" {
  source = "../../yoloform/modules/networking/transit_gateway_centralized_router_for_tiered_vpc_ng"

  env_prefix       = var.env_prefix
  region_az_labels = var.region_az_labels
  vpcs             = module.vpcs

  # not working
  #depends_on = [module.vpcs]
}

#output "tgw" {
#value = module.tgw
#}
