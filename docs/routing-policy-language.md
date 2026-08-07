# Routing Policy Language

## Overview

The routing policy language lets you shape your cloud network topology through
declarative intent. Rather than manually computing which routes should exist
between VPCs, you express constraints and the compiler generates only the
mathematically correct set of routes.

This is a fundamentally different model from traditional cloud networking where
operators manually manage route table entries or rely on runtime control planes
(like AWS Cloud WAN) to evaluate policy opaquely. Here, correctness is
structural: invalid routes cannot be emitted because the policy algebra won't
produce them. `terraform plan` becomes a complete proof of your network's
reachability state before any infrastructure changes.

### Why this is a strong model

1. **Correctness by construction** -- The compiler generates routes from a
   closed algebra. There is no configuration state where an unintended route can
   appear. Every VPC pair resolves to a deterministic reachable/unreachable
   answer at compile time.

2. **You don't need to know routing** -- Operators declare *intent* ("these VPCs
   can reach each other, those cannot"). The compiler handles the cartesian
   product, self-route exclusion, CIDR expansion, and route table distribution.
   The output is auditable in `terraform plan` before anything is applied.

3. **Dual-stack from a single declaration** -- One policy controls both IPv4 and
   IPv6 routing. The IPv6 engine mirrors the IPv4 engine exactly, with null
   checks for VPCs that don't have IPv6 assigned. No separate policy required.

4. **Scope-invariant** -- The same policy language and evaluation works
   identically at every IR level:
   - **Regional IR** (Centralized Router) -- intra-region VPC routing
   - **Global IR** (Full Mesh Trio) -- cross-region VPC routing
   - **Domain IR** (Super Router) -- cross-region and intra-region VPC routing
     across peered routers

## Forwarding Plane vs. Policy Edge

The architecture uses a single TGW route table per TGW. This is a
deliberate design choice: the TGW is treated as a pure forwarding plane. It
knows how to reach every VPC attachment -- full mesh at the transit layer,
unconditionally. TGW routes are generated directly from topology (L0 -> L4) and
are never subject to policy filtering.

Policy exists exclusively at the edge: VPC route tables. A VPC either has a
route to a destination or it doesn't. If the route is absent, the packet never
enters the TGW in the first place.

```
TGW route table  = forwarding plane  (what CAN be forwarded)
VPC route tables = policy edge       (what SHOULD be forwarded)
```

This separation gives us two properties:

1. **Policy changes don't touch the forwarding plane.** Adding or removing a
   deny rule modifies VPC route tables only. The TGW remains stable. You can
   reshape reachability without disrupting the transit infrastructure.

2. **The compilation target stays atomic.** Policy compiles to a single resource
   type (`aws_route`). There's no need to manage per-VPC TGW route tables,
   propagation associations, or route table attachments. One TGW route table,
   one forwarding plane, policy at the edge. The compiler focuses entirely on
   which edges to emit.

The alternative model -- one TGW route table per VPC attachment (enterprise
isolation) -- encodes policy at the forwarding plane. This entangles topology
and constraint: adding a VPC means deciding which other TGW tables should
receive its route. With the single-table model, adding a VPC is a topology
operation (TGW attachment + TGW route). Policy evaluation happens independently
at the edge, where it belongs.

This mirrors how the internet works: BGP policy is applied at the border (edge),
forwarding in the core is policy-unaware. The TGW is the core. VPC route tables
are the border.

## Policy Algebra

Four primitives with fixed precedence (highest to lowest):

```
deny > allow > segments > default
```

| Primitive  | Effect                                                              |
|------------|---------------------------------------------------------------------|
| `deny`     | Unconditionally blocks routes between two VPCs. Highest precedence. |
| `allow`    | Unconditionally permits routes between two VPCs. Overrides segments and default. |
| `segments` | Vertex partitioning. Same-segment VPCs can reach each other. Cross-segment VPCs cannot. |
| `default`  | Fallthrough for anything unmatched. Either `"allow"` (full mesh) or `"deny"` (zero trust). |

Properties of the algebra:
- **Total** -- every VPC pair resolves to reachable or unreachable. No ambiguity.
- **Monotonic** -- deny only subtracts edges, allow only adds (within deny bounds).
- **Commutative** -- `{ from = A, to = B }` blocks/permits both directions.
- **Deterministic** -- same inputs always produce the same route set.

## Default Policy: Full Mesh

The default routing policy is `default = "allow"` which means all VPCs can
reach all other VPCs (full mesh). The following are all equivalent
representations of full mesh:

```hcl
# implicit default (no policy argument)
routing_policy = {}

# explicit allow
routing_policy = {
  default = "allow"
}

# allow with a single segment (all VPCs in one group = full mesh)
routing_policy = {
  default  = "allow"
  segments = {
    all = [module.vpcs["app"], module.vpcs["db"], module.vpcs["web"]]
  }
}
```

These are algebraically identical because:
- An empty policy defaults to `{ default = "allow" }` via the type system's
  optional defaults.
- When `default = "allow"` and no deny rules exist, every VPC pair passes the
  fallthrough check.
- A single segment with all VPCs produces no cross-segment deny rules (there is
  no second segment to deny against). The segment membership permits the same
  VPCs that `default = "allow"` already permits. The result is full mesh.

## Segments

Segments partition VPCs into isolation groups. VPCs in the same segment can
reach each other. VPCs in different segments cannot -- unless explicitly
permitted by an `allow` rule.

```hcl
routing_policy = {
  default  = "deny"
  segments = {
    frontend = [module.vpcs["web"], module.vpcs["api"]]
    backend  = [module.vpcs["db"], module.vpcs["cache"]]
  }
}
```

In this example:
- `web` and `api` can reach each other (same segment)
- `db` and `cache` can reach each other (same segment)
- `web` cannot reach `db` (cross-segment, denied)
- Unsegmented VPCs follow the `default` rule

### A VPC cannot span multiple segments

A VPC may only appear in one segment. This is enforced by validation:

```
A VPC cannot belong to multiple segments. Each VPC (network_cidr) must appear
in only one segment or use allow = [] to create explicit allows across segments.
```

This constraint exists to preserve the mental model: segments are hard
boundaries. There is no segment-to-segment routing by design. If a VPC could
appear in two segments, the partition property breaks and the reachability
answer becomes ambiguous. The algebra requires totality -- every pair must
resolve cleanly.

Notably, the underlying algebra *can* support a VPC appearing in multiple
segments -- if the validation were removed, the compiler would still produce a
route set (the VPC would gain reachability to members of all segments it belongs
to). The math doesn't break. But the mental model does: "segments are isolation
groups" becomes incoherent when a single VPC bridges them implicitly. The
validation exists to keep the language's semantics legible, not because the
engine can't handle the case. If you need a VPC to reach members of multiple
segments, the correct expression is `allow` -- it makes the cross-segment
connectivity explicit and auditable rather than hidden in overlapping membership.

### Punching through segment boundaries

When you need specific cross-segment connectivity, use `allow`:

```hcl
routing_policy = {
  default  = "deny"
  segments = {
    frontend = [module.vpcs["web"], module.vpcs["api"]]
    backend  = [module.vpcs["db"], module.vpcs["cache"]]
  }
  allow = [
    { from = module.vpcs["api"], to = module.vpcs["db"] }
  ]
}
```

Here, `api` can reach `db` (allow overrides segment isolation) but `web` still
cannot reach `db`. The allow rule is surgical -- it permits exactly the pair
specified without weakening the segment boundary for other members.

## Deny Rules

Deny has the highest precedence. It blocks routes regardless of allow rules or
segment membership:

```hcl
routing_policy = {
  default = "allow"
  deny = [
    { from = module.vpcs["quarantine"], to = module.vpcs["production"] }
  ]
}
```

Even though `default = "allow"` would normally permit all connectivity, the deny
rule unconditionally removes routes between `quarantine` and `production`.

## Precedence in Action

Given:
```hcl
routing_policy = {
  default  = "deny"
  segments = {
    trusted = [module.vpcs["app"], module.vpcs["api"], module.vpcs["db"]]
  }
  allow = [
    { from = module.vpcs["monitoring"], to = module.vpcs["app"] }
  ]
  deny = [
    { from = module.vpcs["app"], to = module.vpcs["db"] }
  ]
}
```

Evaluation:
1. `app` -> `db`: **DENIED** (explicit deny, highest precedence, even though same segment)
2. `app` -> `api`: **PERMITTED** (same segment, no deny)
3. `monitoring` -> `app`: **PERMITTED** (explicit allow, overrides default deny)
4. `monitoring` -> `api`: **DENIED** (no allow, not in a segment, default deny)

## From VPC Aggregates to Policy Compilation

Previous versions of Full Mesh Trio and Super Router used a brute-force VPC
aggregate approach to generate cross-region and cross-domain meshes. Each module
would collect all VPCs across regions into a flat aggregate, then use
`setproduct` to compute every possible route table + destination CIDR pair.
The result was always a full mesh -- every VPC could reach every other VPC, with
no ability to selectively control reachability.

This worked for topology generation but left no room for policy. The aggregate
was opaque: a cartesian product in, a route set out, nothing in between where
constraints could be applied.

With routing policy, the architecture changes. The `generate_routes_to_other_vpcs`
function is now a shared compilation unit referenced by all three topology
modules:

- **Centralized Router** -- passes its intra-region VPCs + policy (Regional IR)
- **Full Mesh Trio** -- passes VPCs from all three regions + policy (Global IR)
- **Super Router** -- passes VPCs from local and peer routers + policy (Domain IR)

Each topology module merges its VPCs into a single map, passes it alongside a
`routing_policy` to the shared function, and receives back the policy-filtered
route set. The brute-force aggregate is replaced by a compilation step that can
dynamically shape the mesh based on declared constraints -- for both IPv4 and
IPv6 (single stack and dual stack).

This means policy is no longer a centralized-router-only concept. The same
`deny`, `allow`, `segments`, and `default` primitives work at Global IR and
Domain IR with the same guarantees. An operator can segment cross-region traffic
in Full Mesh Trio or deny specific inter-domain routes in Super Router using the
same language they use for intra-region policy in Centralized Router.

## Scope Invariance

The same `routing_policy` block works at every IR level. The compilation unit
(`generate_routes_to_other_vpcs`) evaluates identically regardless of which
topology scope invokes it:

```hcl
# Regional IR -- Centralized Router (intra-region)
module "centralized_router" {
  source         = "..."
  routing_policy = local.regional_policy
  # ...
}

# Global IR -- Full Mesh Trio (cross-region, 3 regions)
module "full_mesh_trio" {
  source         = "..."
  routing_policy = local.global_policy
  # ...
}

# Domain IR -- Super Router (cross-region + intra-region, peered routers)
module "super_router" {
  source         = "..."
  routing_policy = local.domain_policy
  # ...
}
```

The policy language doesn't know or care which scope it's operating in. It
receives a set of VPCs and a set of constraints, and emits the permitted routes.
The topology modules above it determine which VPCs participate; the route
resources below it determine where edges are written. Policy is the
scope-agnostic middle layer.

## VPC Peering Deluxe Exclusion

VPC Peering Deluxe is intentionally excluded from routing policy. Peering is a
direct point-to-point connection between two VPCs -- by its nature, the act of
creating a peering relationship is itself an explicit allow. There is no
ambiguity about intent: if you peer two VPCs, you want them to reach each other.

Policy applies to transit-routed topologies (Centralized Router, Full Mesh Trio,
Super Router) where a shared forwarding plane connects many VPCs and the
reachability question is non-trivial. In those topologies, full mesh is the
default and policy *constrains* it. VPC Peering Deluxe is the inverse: no
connectivity exists until you explicitly create it. The peering declaration *is*
the policy -- there is nothing to constrain.

This distinction reinforces the language's design: policy is a filter over a
mesh, not a permission system for point-to-point links. Where connectivity
requires explicit construction (peering), policy is redundant. Where
connectivity is implicit (transit routing), policy is essential.

## Test Coverage

The routing policy integration is validated by 66 passing tests via
`terraform test`. These cover:

- Deny rules (IPv4 and IPv6) -- explicit pair blocking, bidirectional enforcement
- Segments (IPv4 and IPv6) -- isolation between groups, same-segment permitting
- Precedence (IPv4 and IPv6) -- deny overriding allow, allow overriding segments,
  segments overriding default, full interaction matrix
- Default behavior -- `default = "allow"` full mesh, `default = "deny"` zero trust
- Edge cases -- empty policy, single segment (equivalent to full mesh), deny with
  no matching VPCs, allow across segment boundaries

Each test asserts on the exact route set the compiler emits -- not just that
routes exist, but that the correct routes exist and no others. This validates
the totality property: every VPC pair is accounted for in every test scenario.
