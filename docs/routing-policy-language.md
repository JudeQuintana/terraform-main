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

### Unsegmented VPCs

VPCs not assigned to any segment are "unsegmented." Their routing behavior
depends on the `default` value and whether multiple segments exist.

**With `default = "allow"` and multiple segments:**
```hcl
routing_policy = {
  default  = "allow"
  segments = {
    frontend = [module.vpcs["web"], module.vpcs["api"]]
    backend  = [module.vpcs["db"], module.vpcs["cache"]]
  }
  # module.vpcs["monitoring"] is unsegmented
}
```

- `monitoring` can reach `web`, `api`, `db`, and `cache` (default allows)
- `web` cannot reach `db` (cross-segment, denied)
- `monitoring` is outside the partition -- cross-segment deny rules are generated
  only between segments, not between a segment and an unsegmented VPC

An unsegmented VPC under `default = "allow"` routes to everything that isn't
explicitly denied. Segment boundaries don't restrict it because it has no
segment membership. It sits outside the partition entirely, so the cross-segment
deny graph doesn't include it.

**With `default = "deny"` and multiple segments:**
```hcl
routing_policy = {
  default  = "deny"
  segments = {
    frontend = [module.vpcs["web"], module.vpcs["api"]]
    backend  = [module.vpcs["db"], module.vpcs["cache"]]
  }
  # module.vpcs["monitoring"] is unsegmented
}
```

- `monitoring` cannot reach anything (default denies, no segment permits it)
- `web` and `api` can still reach each other (same segment)
- `db` and `cache` can still reach each other (same segment)

An unsegmented VPC under `default = "deny"` has zero connectivity. It's neither
permitted by segment membership nor by the default fallthrough. The only way to
grant it reachability is through an explicit `allow` rule:

```hcl
allow = [
  { from = module.vpcs["monitoring"], to = module.vpcs["web"] }
]
```

This makes unsegmented VPCs under `default = "deny"` useful for special-purpose
nodes (monitoring, bastion, logging) that need surgical connectivity to specific
targets without belonging to any isolation group.

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

## Enterprise Routing: Single Table with Policy vs. Per-Attachment Tables

Enterprise AWS environments typically use one TGW route table per VPC attachment
to enforce isolation. Each VPC gets its own route table, and reachability is
controlled by selectively propagating routes between tables. This is the pattern
AWS recommends in its reference architectures and what most consulting firms
implement.

### How the per-attachment model works in practice

With 20 VPCs, you manage 20 TGW route tables. Each table must be configured
with the correct propagation and association rules to express which VPCs can
reach which. Adding a new VPC means:

1. Create a new TGW route table
2. Associate the new attachment to it
3. Decide which existing tables should propagate to the new one (and vice versa)
4. Update potentially many tables when reachability requirements change

This is O(N) operational complexity per VPC addition, and O(N^2) reasoning about
the full reachability matrix. At 50+ VPCs across multiple regions, the
propagation rules become difficult to audit and easy to misconfigure. There is no
single place that answers "can VPC A reach VPC B?" -- you must trace propagation
chains across tables.

### How single table with policy works

One TGW route table. Every VPC attachment is associated and propagated to it.
The TGW forwards everything -- full mesh at the transit layer. Reachability is
controlled exclusively at VPC route tables via compiled policy.

Adding a new VPC means:
1. Create the TGW attachment (topology)
2. The TGW route is generated automatically (forwarding plane)
3. Policy evaluation determines which VPC routes are emitted (edge)

The reachability question is answered in one place: the `routing_policy` block.
`terraform plan` shows exactly which routes exist. No propagation chains to
trace, no tables to cross-reference.

### Why policy at the edge is sufficient

The enterprise concern with a single TGW route table is: "if someone adds a
route manually, traffic can flow anywhere." This is a valid operational risk but
not an architectural one. The correct mitigation is:

- **Drift detection** -- `terraform plan` shows unauthorized routes immediately
- **Preventive controls** -- IAM policies restricting who can modify route tables
- **The policy declaration itself** -- version-controlled, PR-reviewed, auditable

Per-attachment TGW tables provide defense-in-depth at the forwarding plane, but
at the cost of operational complexity that grows quadratically. The routing
policy language provides equivalent segmentation guarantees at the edge with
linear operational complexity and compile-time auditability.

### Compliance frameworks

The routing policy language maps directly to compliance requirements because
policy declarations are auditable artifacts:

**PCI-DSS (network segmentation):** Requires demonstrable isolation between
cardholder data environments and other networks. A `segments` declaration with
payment workloads in one segment and non-payment in another is the proof.
`terraform plan` output showing zero routes between segments is the audit
evidence. No runtime testing required -- the compiler guarantees it.

**HIPAA (access controls):** Requires that electronic protected health
information (ePHI) is accessible only to authorized systems. `default = "deny"`
with explicit `allow` rules to ePHI-hosting VPCs produces a minimal
connectivity set. The policy declaration documents the access control. The plan
output proves enforcement.

**FedRAMP / NIST 800-53 (boundary protection):** Requires managed interfaces at
system boundaries with deny-all, permit-by-exception posture. This is literally
`default = "deny"` with `allow` rules. The policy language's precedence algebra
(deny > allow > segments > default) maps to the control hierarchy these
frameworks expect.

**SOC 2 (logical access):** Requires evidence that logical access to systems is
restricted and monitored. The policy declaration is the restriction. Git history
on the policy file is the change log. Plan output diffed between commits is the
access change audit trail.

In each case, the compliance artifact is the policy itself -- not a separate
document describing what the network *should* look like, but the actual
declaration that *compiles to* the network. The gap between documentation and
implementation that auditors typically probe does not exist. The documentation
*is* the implementation.

## Comparison: TGW Policy Tables and Cloud WAN

### TGW Policy Tables

TGW policy tables are an AWS primitive that associates a route table per
attachment and selectively propagates routes between them. Policy is encoded as
propagation/association rules at the forwarding plane.

| | TGW Policy Tables | Routing Policy Language |
|---|---|---|
| Policy location | Forwarding plane (TGW) | Edge (VPC route tables) |
| Evaluation | Runtime (AWS control plane) | Compile time (`terraform plan`) |
| Visibility | Routes visible after propagation | Routes visible before apply |
| Primitives | Propagation, association, static routes | deny, allow, segments, default |
| Topology coupling | Adding a VPC requires updating table associations | Adding a VPC is independent of policy |
| Scale | 20 route tables per TGW (soft limit) | Bounded by route table entry limits (50 per table default) |
| Defense in depth | Forwarding plane blocks at TGW | Edge blocks at VPC route table |
| Operational model | Manage N tables and propagation rules | Manage one policy declaration |

TGW policy tables encode reachability at the forwarding plane. The routing
policy language encodes reachability at the edge. Both achieve segmentation.
They differ in where the enforcement boundary sits, how changes propagate, and
what the operator manages day-to-day. TGW policy tables provide an additional
enforcement layer at the transit level. The routing policy language provides
compile-time visibility of the complete route set before any changes are applied.

### AWS Cloud WAN

Cloud WAN provides a managed core network with a policy document evaluated by
AWS's control plane. Operators submit a JSON policy, and AWS manages route
propagation, segment isolation, and cross-region connectivity.

| | Cloud WAN | Routing Policy Language |
|---|---|---|
| Evaluation | Runtime (AWS control plane) | Compile time (`terraform plan`) |
| Convergence | Minutes (control plane propagation) | Immediate (API calls to route tables) |
| Dry run | Change set preview (limited detail) | Full route enumeration before apply |
| Segmentation | Segments with attachment-level membership | Segments with CIDR-level membership |
| Cross-segment | Segment actions (sharing and routing rules) | `allow` rules (per-VPC-pair granularity) |
| Precedence | Implicit (segment membership determines routing) | Explicit algebra (deny > allow > segments > default) |
| Infrastructure | Managed core network (per-attachment + per-GB fees) | Standard TGW (attachment pricing only) |
| Operational model | AWS manages the routing loop | Operator manages the compiler input |
| Multi-region | Built-in (core network spans regions) | Topology modules compose regions explicitly |
| Dual-stack | Supported within segment policy | Single declaration covers both stacks |

Cloud WAN and the routing policy language address the same problem: expressing
network segmentation intent without manually configuring individual routes. They
differ architecturally. Cloud WAN evaluates policy at runtime inside a managed
control plane -- the operator delegates route computation to AWS. The routing
policy language evaluates at compile time inside the operator's pipeline -- the
operator sees the full route set in `terraform plan` output before applying.
Cloud WAN provides managed infrastructure and operational simplicity at the cost
of runtime opacity and per-GB processing fees. The routing policy language
provides compile-time determinism and standard TGW infrastructure at the cost of
the operator owning the compilation step.

## Test Coverage

The routing policy integration in the `generate_routes_to_other_vpcs` function
is validated by 66 passing tests via `terraform test`. These cover:

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
