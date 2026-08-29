# Compiler Semantic Toolchain

Semantic outputs that make the compiler's decisions inspectable. Enable via the `inspect` field nested inside each IR module's config object (`centralized_router.inspect`, `full_mesh_trio.inspect`, `super_router.inspect`) to dump artifacts to JSON files.

```hcl
centralized_router = {
  # ...
  inspect = {
    reachability = true
    diagnostics  = true
    provenance   = true
    policy_diff = {
      previous_reachability = jsondecode(file("inspect/centralized-router-name-reachability.json"))
    }
    equivalence = {
      equivalent_routing_policy = { ... }
    }
  }
}
```

## Reachability Matrix

The algebra's per-pair verdict as structured data. For every VPC pair, shows whether connectivity is permitted or denied and which precedence level determined the outcome.

```json
{
  "app:db": "permitted:segment",
  "app:cache": "permitted:allow",
  "web:db": "denied:cross-segment",
  "monitor:db": "denied:default"
}
```

Pairs are deduplicated since rules are bidirectional. `"app:db"` implicitly covers `"db:app"`. Only the lexicographically-first key is shown.

Six possible verdicts mapping directly to the precedence chain:
- `permitted:allow` - explicit allow rule fired
- `permitted:segment` - same-segment membership
- `permitted:default` - default="allow" fallthrough
- `denied:deny` - explicit deny rule (highest precedence)
- `denied:cross-segment` - different segments under default="allow"
- `denied:default` - default="deny" fallthrough

This is the compiled intermediate representation made inspectable. It separates "what the policy decided" from "what routes were emitted" and makes the algebra's output auditable without understanding route tables.

## Diagnostics

Compiler warnings for policy states that are valid but likely unintentional.

```json
[
  "VPC \"monitoring\" has zero connectivity. It is unsegmented under default=\"deny\" with no allow rules.",
  "Segment \"isolated\" contains only 1 VPC. Single-member segments have no routing effect under default=\"deny\".",
  "Deny rule { app -> db } is redundant: this pair would already be denied without it.",
  "Allow rule { app -> db } is redundant: this pair would already be permitted without it.",
  "Policy has 1 segment under default=\"allow\". A single segment has no routing effect when there is no other segment to deny against."
]
```

Five classes of warnings:
- **Zero connectivity** - a VPC with no outbound reachability (unsegmented under default="deny" with no allow rules)
- **Single-member segment** - a segment with one VPC has no routing effect under default="deny" (algebraically equivalent to unsegmented)
- **Redundant deny** - a deny rule on a pair that would already be denied without it (default="deny" with no allow or segment for that pair)
- **Redundant allow** - an allow rule on a pair that would already be permitted without it (default="allow" with no cross-segment deny for that pair)
- **Single segment no effect** - one segment under default="allow" has no routing effect (cross-segment denies require at least two segments)

This is `-Wall` for network policy. The compiler tells you when your program is technically valid but probably wrong.

## Provenance

Debug symbols for emitted routes. Each route carries metadata tracing it back to the source VPC pair and the policy primitive that authorized it.

```json
[
  {
    "route_table_id": "rtb-abc",
    "destination_cidr_block": "10.0.64.0/18",
    "from": "app",
    "to": "db",
    "verdict": "permitted",
    "reason": "segment"
  },
  {
    "route_table_id": "rtb-def",
    "destination_cidr_block": "172.18.0.0/18",
    "from": "app",
    "to": "cache",
    "verdict": "permitted",
    "reason": "allow"
  }
]
```

When you see a route in a VPC route table, provenance traces it back to which policy primitive caused it. This is the link between compiled output and source program. It answers "why does this route exist?" and "which policy rule authorized this path?"

## Policy Diff

Incremental compilation preview. Given the previous reachability matrix (from a prior run), computes what changed in connectivity at the semantic level.

```json
{
  "added": ["app:monitor"],
  "removed": ["app:db"],
  "unchanged": ["api:app", "api:web"]
}
```

Pairs are deduplicated since rules are bidirectional. `"app:db"` implicitly covers `"db:app"`. Only the lexicographically-first key is shown, no redundant mirror entries.

Pass the previous reachability via `inspect.policy_diff.previous_reachability` nested inside the IR module's config object:

```hcl
centralized_router = {
  # ...
  inspect = {
    policy_diff = {
      previous_reachability = jsondecode(file("inspect/myrouter-reachability.json"))
    }
  }
}
```

The workflow:
1. Enable `inspect.reachability = true` to dump the reachability matrix to a JSON file
2. Change the routing policy
3. Pass the previous JSON file via `inspect.policy_diff.previous_reachability`
4. The diff output shows added/removed/unchanged pairs

This answers "what did this policy change actually do?" at the semantic level. `terraform plan` shows route additions/removals (assembly diff). Policy diff shows reachability changes (source-level diff).

## Equivalence

Proves that two different policy declarations produce identical reachability. This is the network policy equivalent of "these two programs compute the same function."

```json
{
  "equivalent": true,
  "mismatches": {}
}
```

When policies differ:

```json
{
  "equivalent": false,
  "mismatches": {
    "app:db": {
      "routing_policy": "permitted:default",
      "equivalent_routing_policy": "denied:deny"
    }
  }
}
```

Mismatches are deduplicated since rules are bidirectional. `"app:db"` implicitly covers `"db:app"`. Only the lexicographically-first key is shown.

Pass the second policy via `inspect.equivalence.equivalent_routing_policy` nested inside the IR module's config object:

```hcl
centralized_router = {
  # ...
  routing_policy = {
    default = "allow"
    deny    = [{ from = vpcs["app"], to = vpcs["db"] }]
  }
  inspect = {
    equivalence = {
      equivalent_routing_policy = {
        default = "deny"
        allow = [
          { from = vpcs["app"], to = vpcs["web"] },
          { from = vpcs["db"], to = vpcs["web"] },
        ]
      }
    }
  }
}
```

Equivalence compares permit/deny outcomes only. The verdict reason (which rule caused it) is irrelevant. Two policies are equivalent if every VPC pair has the same reachability regardless of how it was derived.

Use cases:
- Migration proof: rewriting from allow-with-denies to deny-with-allows without changing behavior
- Simplification: proving a shorter policy is equivalent to a longer one
- Refactoring: reorganizing segments into explicit allows (or vice versa) with proof of no regression
