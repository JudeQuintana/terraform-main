```
     ____.             ________        ________
    |    |____  ___.__.\_____  \       \_____  \   ____   ____
    |    \__  \<   |  | /  / \  \       /   |   \ /    \_/ __ \
/\__|    |/ __ \\___  |/   \_/.  \     /    |    \   |  \  ___/
\________(____  / ____|\_____\ \_/_____\_______  /___|  /\___  >
              \/\/            \__>_____/       \/     \/     \/

--=[ PrEsENtZ ]=--

--=[ From O(N² + V²) to O(N + V): Automated Multi-TGW Mesh Configuration Through Functional Composition ]=--

--=[ A personal contribution to the cloud networking community ]=--

--=[ Create -> Iterate -> Combine | #End2EndBurner ]=--
```

Author: Jude Quintana

## 1. Abstract

Modern AWS multi-VPC architectures face a fundamental scalability challenge: full-mesh connectivity across N Transit Gateways (TGWs) requires N(N–1)/2 adjacencies (O(N²)), while V attached VPCs incur O(V²) routing and security propagation. Because VPCs inherit connectivity transitively through TGWs, expansion across regions and address families (IPv4/IPv6) produces thousands of configuration artifacts and substantial recurring NAT Gateway cost. Imperative implementation approaches typically fail to scale beyond 10–15 TGWs or 50+ VPCs.

This paper presents a production-validated multi-region architecture that reduces topology implementation from O(N² + V²) imperative configuration to O(N + V) declarative specification. Using compositional Terraform modules and pure-function IR transformations, the system automatically infers TGW adjacencies, generates routing tables, and applies foundational security rules. In a 3-TGW, 9-VPC, 3-region deployment, the architecture synthesizes 1,308 AWS resources from 174 lines of configuration, achieving a 7.5× code-amplification factor and reducing implementation time from 31.2 hours to 15.75 minutes (a 120× speedup). Centralized egress enables O(1) NAT Gateway scaling, reducing gateways from 18 to 6 and lowering cost by 67%. The 1,308-resource total includes all AWS infrastructure objects (routes, security rules, attachments, subnets, route tables, and gateways), whereas the 852-route and 108-rule figures refer specifically to routing artifacts.

Mathematical analysis confirms linear configuration growth, a 27% entropy reduction, and formal cost-performance trade-offs between TGW and VPC Peering paths. The system functions as an embedded DSL for AWS mesh networking, applying compiler-style IR passes to provide deterministic, declarative topology programming with referential transparency.

## 2. Introduction

Large-scale AWS environments commonly adopt a multi-VPC model to isolate workloads, enforce blast-radius boundaries, and support multi-region resilience. Mature cloud organizations routinely operate 15–50 VPCs across several AWS regions, with some enterprises exceeding 100 VPCs globally. However, creating consistent connectivity across these environments exposes a fundamental scaling challenge: while VPCs do not peer directly, the underlying Transit Gateway (TGW) mesh requires explicit configuration of all adjacency relationships.

For N Transit Gateways forming a full mesh, the number of TGW-to-TGW peering relationships grows quadratically:

```
F(N) = N(N−1)/2 = O(N²),  where N = number of TGWs
```

For V VPCs attached across these TGWs, operators must also configure route tables, security group rules, TGW attachments, and propagation settings across multiple availability zones and CIDR blocks. VPC-level routing and security relationships scale as O(V²), independently of TGW adjacency. Even a modest 9-VPC deployment across 3 TGWs produces:

- 1,152 route entries (theoretical maximum assuming full dual-stack, multi-CIDR routing)

- 432 security group rules (theoretical maximum for two protocols across IPv4/IPv6 families)

- ≈1,800 total AWS resources

- ≈45 engineering hours for imperative implementation

Measured production deployments typically generate fewer entries (e.g., 852 routes and 108 foundational security rules) due to topology optimizations such as isolated subnets and selective protocol enablement. These measured and theoretical values both validate O(V²) scaling for VPC-level artifacts; derivations appear in the supplemental materials.

As cloud estates expand beyond ~15 VPCs, these quadratic VPC-level configuration requirements become operationally prohibitive, consuming weeks of engineering time and introducing growing opportunities for misconfiguration. Multi-region deployments amplify the problem: TGW peering (O(N²)), transitive route propagation, and IPv4/IPv6 dual-stack requirements multiply configuration effort across regions. At 20 VPCs spanning 3 TGWs, imperative implementation exceeds 300 hours—equivalent to two engineer-months of labor.

### 2.1 Problem Statement

AWS exposes powerful networking primitives—VPCs, Transit Gateways (TGWs), NAT Gateways, Egress-only Internet Gateways (EIGWs), and IPv4/IPv6 CIDR blocks—but provides no abstraction for expressing multi-region mesh topologies declaratively. Engineers must imperatively implement routing, peering, propagation, and security relationships across regions, creating two independent quadratic scaling problems:

- O(N²) TGW mesh adjacency for N Transit Gateways
- O(V²) VPC-level routing and security propagation for V VPCs

Together, these produce brittle, labor-intensive topologies and five systemic failure modes:

**Quadratic VPC-level configuration burden:**
Adding the V-th VPC requires updating V–1 existing VPCs with new routes and security rules (O(V²)). Even modest environments (e.g., V=20) exceed 300 engineering hours for initial configuration.

**Quadratic TGW adjacency growth in multi-region networks:**
Full-mesh routing across N regions requires N(N–1)/2 TGW peering relationships, each with routing and propagation tasks. At only N=5, operators already manage 10 TGW adjacencies with region-specific constraints and propagation rules.

**High configuration error rates:**
Imperative creation of hundreds of VPC-level and TGW-level relationships leads to:
- routing inconsistency
- propagation drift
- asymmetric connectivity
- intermittent cross-region failures

Industry analyses attribute 60–80% of outages to configuration errors.

**Excessive NAT Gateway cost due to per-VPC egress:**
Default architectures deploy NAT Gateways in every VPC × every AZ, yielding V × A gateways where constant infrastructure would suffice.

Example: With V = 9 and A = 2, operators deploy 18 NAT Gateways at approximately $591/month ($7,092 annually), even though centralized egress requires only 6. This represents a 67% avoidable cost overhead.

**Non-repeatable and non-verifiable topology logic:**
Critical connectivity logic lives in:
- tribal knowledge
- ad hoc runbooks
- implicit conventions

Not in executable specification. Teams cannot reliably:
- reproduce environments
- audit changes
- validate correctness prior to deployment

This prevents networks from achieving deterministic, infra-as-code workflows.

### 2.2 Key Insight

Modern AWS networking lacks a declarative abstraction for expressing multi-region, multi-VPC mesh topologies. Engineers must imperatively implement all TGW-to-TGW adjacencies (O(N²)) and all VPC-level routing relationships (O(V²)) by hand. The central insight of this architecture is that these quadratic relationships can be inferred rather than declared.

This system achieves a complexity transformation:

> Encode topology intent as O(N + V) data structures—N Transit Gateway declarations + V VPC declarations—and automatically synthesize all O(N²) TGW adjacencies and all O(V²) VPC propagation relationships through a structured, multi-pass compilation pipeline.

The topology compiler consists of three required stages (AST construction, Regional IR, Global IR) and one optional optimization pass (VPC Peering Deluxe), mirroring the structure of multi-pass compilers.

⸻

**Stage 1 — AST Construction (Tiered VPC-NG)**

Tiered VPC-NG serves as the abstract syntax tree (AST) for the topology:
- Each VPC is a typed object specifying CIDRs, tiers (private/public/isolated), IPv4/IPv6 combinations, NAT policies, and egress attributes.
- Validations enforce semantic correctness (unique CIDRs, dual-stack integrity, NAT constraints, AZ structure).
- The output is a VPC AST map of size V, supplying the compiler with structured inputs.

This stage contains no routing logic. It defines what exists, not how it connects.

⸻

**Stage 2 — Regional IR Pass (Centralized Router)**

Centralized Router transforms the VPC AST for a single region into a regional intermediate representation (IR):
- Creates exactly one TGW per region.
- Maps VPC attachments and synthesizes TGW route tables.
- Applies centralized egress semantics.
- Generates all intra-region V×V route expansions via the pure-function module generate_routes_to_other_vpcs.

Crucially:
- Centralized Router is responsible for O(V²) relationships within a region.
- It does not perform TGW-to-TGW adjacency—it assumes one TGW per region.
- All IR passes are implemented as pure-function Terraform modules—zero-resource transformations that operate exclusively on data structures, enabling deterministic outputs, referential transparency, property-based testing, and formal verification of routing logic.

The IR emitted from this stage is:

```
Regional IR = {
  TGW metadata,
  VPC attachment graph,
  V×V routing expansion for the region
}
```


This mirrors a compiler’s middle-end optimization pass: expanding abstract declarations into concrete routing and connectivity semantics.

⸻

Stage 3 — Global IR Pass (Full Mesh Trio)

Full Mesh Trio composes multiple regional meshes into a global mesh:
- Establishes all N×N TGW peering adjacencies.
- Creates cross-region V×V routing expansions so that VPCs in different regions inherit full reachability.
- Merges three regional IRs (one per region) into a single global IR representing a multi-region mesh.

Thus:
- Full Mesh Trio is responsible for O(N²) TGW relationships and cross-region O(V²) propagation.
- Regional and global complexity dimensions remain cleanly separated.

This stage corresponds to a compiler’s late-stage code generation: assembling multiple modules into a linked, globally optimized output.

⸻

Optional Optimization Pass — VPC Peering Deluxe (Selective Direct Edges)

On top of the TGW-based global mesh, specific traffic flows may require:
- lower latency
- predictable cost boundaries
- microsegmented subnet-level paths

VPC Peering Deluxe provides an optional overlay optimization pass:
- Inserts direct VPC-to-VPC edges (intra- or cross-region).
- Can operate on full-subnet sets or imperatively selected subnet CIDRs.
- Does not alter global complexity classes; each peering edge is an O(1) insertion into the global graph.

This aligns with compiler peephole or profile-guided optimization: selective refinement of hot paths without changing the high-level program.

⸻

Overall Key Insight

By treating cloud topology as a compilation problem with:
1. AST (Tiered VPC-NG)
2. Regional IR passes (Centralized Router)
3. Global IR pass (Full Mesh Trio)
4. Optional optimization passes (VPC Peering Deluxe)

the system transforms an O(N² + V²) imperative configuration burden into O(N + V) declarative input.

The remaining quadratic complexity is pushed entirely into deterministic, pure-function IR transformations, enabling:
- referential transparency
- formal reasoning
- entropy reduction
- repeatable, testable infrastructure synthesis

This shift—from hand-managed relationships to compiler-generated topology—is the core conceptual contribution of the architecture.

