locals {
  routing_policy_intra_region_use1 = {
    default = "deny"
    allow = [
      { from = module.vpcs_use1["app3"], to = module.vpcs_use1["infra3"] },
    ]

    segments = {
      workloads = [
        module.vpcs_use1["app3"],
        module.vpcs_use1["general3"],
      ]
      management = [
        module.vpcs_use1["infra3"],
      ]
    }
  }

  # full mesh
  routing_policy_intra_region_use2 = {
    default = "allow"
  }

  # full mesh
  routing_policy_intra_region_usw2 = {
    default = "allow"
  }

  routing_policy_cross_region_use1_use2_usw2 = {
    default = "deny"
    allow = [
      { from = module.vpcs_use2["infra1"], to = module.vpcs_usw2["infra2"] },
    ]

    segments = {
      shared = [
        module.vpcs_use1["infra3"],
        module.vpcs_usw2["app2"],
      ]
      # Solo-member segment: algebraically equivalent to unsegmented under default="deny".
      # Kept to document intent — app1 is deliberately isolated from the shared group.
      restricted = [
        module.vpcs_use2["app1"],
      ]
    }
  }
}
