locals {
  policy = {
    deny = [
      { from_vpc = module.vpcs_use1["app3"], to_vpc = module.vpcs_use1["general3"] }
    ]

    segments = {
      trusted = [
        module.vpcs_use1["app3"],
        module.vpcs_use1["general3"]
      ]
    }
  }
}
