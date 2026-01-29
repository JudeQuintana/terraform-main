# cross region peering, only route specific subnets across peering connection
# more cost effective vs using transit gateway for cross region traffic
module "vpc_peering_deluxe_usw2_general1_to_use1_general2" {
  source  = "JudeQuintana/vpc-peering-deluxe/aws"
  version = "1.0.1"

  providers = {
    aws.local = aws.usw2
    aws.peer  = aws.use1
  }

  env_prefix = var.env_prefix
  vpc_peering_deluxe = {
    local = {
      vpc = lookup(module.vpcs_usw2, "general1")
      only_route = {
        # usw2a experiment1 ipv4 private subnet
        subnet_cidrs = ["192.168.0.0/24"]
        # usw2c random2 ipv6 private subnet
        ipv6_subnet_cidrs = ["2600:1f24:66:c102::/64"]
      }
    }
    peer = {
      vpc = lookup(module.vpcs_use1, "general2")
      only_route = {
        # use1a experiment2 ipv4 subnet
        subnet_cidrs = ["192.168.130.0/24"]
        # use1c experiment14 ipv6 subnet
        ipv6_subnet_cidrs = ["2600:1f28:3d:c40a::/64"]
      }
    }
  }
}

# intra region vpc peering, route all subnets across peering connection
# more cost effective vs using transit gateway when cidr traffic is within same AZ.
module "vpc_peering_deluxe_usw2_app1_to_usw2_cicd1" {
  source  = "JudeQuintana/vpc-peering-deluxe/aws"
  version = "1.0.1"

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
      vpc = lookup(module.vpcs_another_usw2, "cicd1")
    }
  }
}

