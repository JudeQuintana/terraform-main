locals {
  inspect_use1 = {
    reachability = true
    diagnostics  = true
    provenance   = true

    policy_diff = {
      # usually the reachability is generated already so you can just do:
      # previous_reachability = jsondecode(file("inspect/myrouter-reachability.json"))
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
        }
      }
    }
  }

  inspect_use1_use2_usw2 = {
    reachability = true
    diagnostics  = true
  }
}
