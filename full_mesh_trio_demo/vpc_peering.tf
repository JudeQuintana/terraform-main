# VPC Peering Deluxe module will create appropriate routes for all subnets in each cross region Tiered VPC-NG by default unless specific subnet cidrs are selected to route across the VPC peering connection via only_route_subnet_cidrs list is populated.
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

