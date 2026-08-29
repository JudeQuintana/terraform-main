locals {
  inspect_use1 = {
    reachability = true
    diagnostics  = true
    provenance   = true
    policy_diff = {
      previous_reachability = {
        "app3:general3"   = "permitted:segment"
        "app3:infra3"     = "permitted:allow"
        "general3:infra3" = "denied:default"
      }
    }
    equivalence = {
      equivalent_routing_policy = {
        default = "deny"
        allow = [
          { from = module.vpcs_use1["app3"], to = module.vpcs_use1["infra3"] },
        ]

        segments = {
          workloads = [
            module.vpcs_use1["app3"],
            module.vpcs_use1["general3"],
          ]
          #management = [
          #module.vpcs_use1["infra3"],
          #]
        }
      }
    }
  }
}
