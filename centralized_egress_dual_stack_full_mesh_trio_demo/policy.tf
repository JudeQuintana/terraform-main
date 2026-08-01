locals {
  policy_use1 = {
    default = "deny"
    allow = [
      { from_vpc = module.vpcs_use1["app3"], to_vpc = module.vpcs_use1["infra3"] },
    ]

    segments = {
      trusted = [
        module.vpcs_use1["app3"],
        module.vpcs_use1["general3"],
      ]
      other = [
        module.vpcs_use1["infra3"],
      ]
    }
  }

  policy_use2 = {
    default = "allow"
  }

  policy_usw2 = {
    default = "allow"
  }

  policy_use1_use2_usw2 = {
    default = "deny"
    allow = [
      { from_vpc = module.vpcs_use2["infra1"], to_vpc = module.vpcs_usw2["infra2"] },
    ]

    segments = {
      cross-region = [
        module.vpcs_use1["infra3"],
        module.vpcs_usw2["app2"],
      ]
      cross-region2 = [
        module.vpcs_use2["app1"],
      ]
    }
  }
}
