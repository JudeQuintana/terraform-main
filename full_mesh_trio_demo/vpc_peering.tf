# cross region peering, only route specific subnets across peering connection
module "vpc_peering_deluxe_use1_general2_to_use2_cicd1" {
  source  = "JudeQuintana/vpc-peering-deluxe/aws"
  version = "1.0.0"

  providers = {
    aws.local = aws.use1
    aws.peer  = aws.use2
  }

  env_prefix = var.env_prefix
  vpc_peering_deluxe = {
    local = {
      vpc = lookup(module.vpcs_use1, "general2")
      # use1 public random1
      only_route_subnet_cidrs = ["192.168.13.0/28"]
    }
    peer = {
      vpc = lookup(module.vpcs_use2, "cicd1")
      # use2 private jenkins1
      only_route_subnet_cidrs = ["172.16.1.0/24"]
    }
  }
}

# intra region vpc peering, route all subnets across peering connection
module "vpc_peering_deluxe_usw2_app1_to_usw2_general1" {
  source  = "JudeQuintana/vpc-peering-deluxe/aws"
  version = "1.0.0"

  providers = {
    aws.local = aws.usw2
    aws.peer  = aws.usw2
  }

  env_prefix = var.env_prefix
  vpc_peering_deluxe = {
    local = {
      vpc = lookup(module.vpcs_usw2, "app1")
    }
    peer = {
      vpc = lookup(module.vpcs_usw2, "general1")
    }
  }
}

