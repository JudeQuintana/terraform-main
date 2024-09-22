module "full_mesh_trio" {
  #source  = "JudeQuintana/full-mesh-trio/aws"
  #version = "1.0.0"
  source = "git@github.com:JudeQuintana/terraform-modules.git//networking/full_mesh_trio?ref=dual-stack-full-mesh-trio"

  providers = {
    aws.one   = aws.use1
    aws.two   = aws.use2
    aws.three = aws.usw2
  }

  env_prefix = var.env_prefix
  full_mesh_trio = {
    one = {
      centralized_router = module.centralized_router_use1
    }
    two = {
      centralized_router = module.centralized_router_use2
    }
    three = {
      centralized_router = module.centralized_router_usw2
    }
  }
}

output "full_mesh_trio" {
  value = module.full_mesh_trio
}
