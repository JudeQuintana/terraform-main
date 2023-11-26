# cross region vpc peering, should work for intra vpc peering
# generates appropriate routes for all subnet cidrs in each VPC or select specific subnet cidrs to route across the peering connection
module "vpc_peering_deluxe" {
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/vpc_peering_deluxe?ref=vpc-peering"

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

