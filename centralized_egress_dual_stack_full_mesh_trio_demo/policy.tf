locals {
  policy = {
    deny = [
      #{ from_vpc = module.vpcs_use1["app3"], to_vpc = module.vpcs_use1["general3"] },
      { from_vpc = module.vpcs_use1["app3"], to_vpc = module.vpcs_usw2["infra2"] }
    ]

    segments = {
      trusted = [
        module.vpcs_use1["app3"],
        module.vpcs_use1["general3"],
        module.vpcs_usw2["app2"],
      ]
      other_trusted = [module.vpcs_use2["infra1"], module.vpcs_usw2["infra2"]]
    }
  }
}
