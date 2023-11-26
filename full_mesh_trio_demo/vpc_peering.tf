# cross region vpc peering, should work for intra vpc peering
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
    }
    peer = {
      vpc = lookup(module.vpcs_use2, "cicd1")
    }
  }
}

