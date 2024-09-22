# cross region peering, only route specific subnets across peering connection
module "vpc_peering_deluxe_use1_general3_to_use2_app1" {
  #source  = "JudeQuintana/vpc-peering-deluxe/aws"
  #version = "1.0.0"
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/vpc_peering_deluxe?ref=dual-stack-full-mesh-trio"

  providers = {
    aws.local = aws.use1
    aws.peer  = aws.use2
  }

  env_prefix = var.env_prefix
  vpc_peering_deluxe = {
    local = {
      vpc = lookup(module.vpcs_use1, "general3")
      only_route = {
        subnet_cidrs      = ["192.168.65.0/24"]
        ipv6_subnet_cidrs = ["2600:1f28:3d:c400::/64"]
      }
    }
    peer = {
      vpc = lookup(module.vpcs_use2, "app1")
      only_route = {
        subnet_cidrs      = ["172.16.128.0/24"]
        ipv6_subnet_cidrs = ["2600:1f26:21:c004::/64"]
      }
    }
  }
}

## inter region vpc peering, route all subnets across peering connection
module "vpc_peering_deluxe_usw2_app2_to_usw2_general2" {
  #source  = "JudeQuintana/vpc-peering-deluxe/aws"
  #version = "1.0.0"
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/vpc_peering_deluxe?ref=dual-stack-full-mesh-trio"

  providers = {
    aws.local = aws.usw2
    aws.peer  = aws.usw2
  }

  env_prefix = var.env_prefix
  vpc_peering_deluxe = {
    local = {
      vpc = lookup(module.vpcs_usw2, "app2")
    }
    peer = {
      vpc = lookup(module.vpcs_usw2, "general2")
    }
  }
}

