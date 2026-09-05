locals {
  inspect_use1 = {
    reachability         = true
    diagnostics          = true
    provenance           = true
    policy_normalization = true
    segment_report       = true
    connectivity_graph   = true

    policy_diff = {
      # usually the reachability is generated already so you can just do:
      # previous_reachability = jsondecode(file("inspect/myrouter-reachability.json"))
      # and change the local.routing_policy_use1 to see what's changed.
      # blash radius will also show as part of the ouput
      previous_reachability = {
        "app3:general3"   = "permitted:segment"
        "app3:infra3"     = "permitted:allow"
        "general3:infra3" = "denied:default"
      }
    }

    equivalence = {
      # use this to test against routing_policy to verify equivalent policies algebraically
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

  inspect_use2 = {
    segment_report     = true
    connectivity_graph = true
  }

  inspect_usw2 = {
    diagnostics = true
  }

  inspect_use1_use2_usw2 = {
    reachability         = true
    diagnostics          = true
    policy_normalization = true
    segment_report       = true
    connectivity_graph   = true
    assertions = {
      must_deny = [
        { from = module.vpcs_usw2["app2"], to = module.vpcs_use2["app1"] },
      ]
      must_permit = [
        { from = module.vpcs_use2["infra1"], to = module.vpcs_usw2["infra2"] },
      ]
    }
  }
}
