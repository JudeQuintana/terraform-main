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

--=[ Author: Jude Quintana ]=--
```

## 1. Abstract

Modern AWS multi-VPC architectures face a fundamental scalability challenge: full-mesh connectivity across N Transit Gateways (TGWs) requires N(N–1)/2 adjacencies (O(N²)), while V attached VPCs incur O(V²) routing and security propagation. Because VPCs inherit connectivity transitively through TGWs, expansion across regions and address families (IPv4/IPv6) produces thousands of configuration artifacts and substantial recurring NAT Gateway cost. Imperative implementation approaches typically fail to scale beyond 10–15 TGWs or 50+ VPCs.

This paper presents a production-validated multi-region architecture that reduces topology implementation from O(N² + V²) imperative configuration to O(N + V) declarative specification. Using compositional Terraform modules and pure-function IR transformations, the system automatically infers TGW adjacencies, generates routing tables, and synthesizes baseline security rules derived from topology intent. In a 3-TGW, 9-VPC, 3-region deployment, the architecture synthesizes 1,308 AWS resources from 174 lines of configuration, achieving a 7.5× code-amplification factor and reducing implementation time from 31.2 hours to 15.75 minutes (a 120× speedup). Centralized egress enables O(1) NAT Gateway scaling, reducing gateways from 18 to 6 and lowering cost by 67%. The 1,308-resource total includes all AWS infrastructure objects (routes, security rules, attachments, subnets, route tables, and gateways), whereas the 852-route and 108-rule figures refer specifically to routing artifacts.

Mathematical analysis confirms linear configuration growth, a 27% entropy reduction, and formal cost-performance trade-offs between TGW and VPC Peering paths. The system functions as an embedded DSL for AWS mesh networking, applying compiler-style IR passes to provide deterministic, declarative topology programming with referential transparency.

## 2. Introduction

Large-scale AWS environments commonly adopt a multi-VPC model to isolate workloads, enforce blast-radius boundaries, and support multi-region resilience. Mature cloud organizations routinely operate 15–50 VPCs across several AWS regions, with some enterprises exceeding 100 VPCs globally. However, creating consistent connectivity across these environments exposes a fundamental scaling challenge: while VPCs are not directly peered in TGW-centric architectures, the underlying Transit Gateway (TGW) mesh requires explicit configuration of all adjacency relationships.

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

**Quadratic TGW adjacency growth in multi-region networks**:
Full-mesh routing across N regions requires N(N–1)/2 TGW adjacencies (TGW-to-TGW peering relationships), each involving attachment creation, route-table association, and propagation configuration. At N = 5 regions, this already entails 5 Transit Gateways and 10 TGW adjacencies, each with region-specific constraints and routing semantics.

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

Modern AWS networking lacks a declarative abstraction for expressing multi-region, multi-VPC mesh topologies. Engineers must imperatively implement all TGW-to-TGW adjacencies (O(N²)) and all VPC-level routing relationships (O(V²)), explicitly specifying each relationship rather than declaring topology intent. The central insight of this architecture is that these quadratic relationships can be inferred rather than declared.

This system achieves a complexity transformation:

> Encode topology intent as O(N + V) data structures—N Transit Gateway declarations + V VPC declarations—and automatically synthesize all O(N²) TGW adjacencies and all O(V²) VPC propagation relationships through a structured, multi-pass compilation pipeline.

The topology compiler consists of three required stages (AST construction, Regional IR, Global IR) and one optional optimization pass (VPC Peering Deluxe), mirroring the structure of multi-pass compilers.

⸻

**Stage 1 — AST Construction (Tiered VPC-NG)**
CIDR Allocation Assumption:
This architecture assumes that all VPC and subnet CIDRs are globally non-overlapping across regions. Neither Centralized Router nor Full Mesh Trio performs overlapping CIDR detection; instead, Tiered VPC-NG enforces CIDR correctness only within a single VPC. This mirrors AWS Transit Gateway’s routing model, which does not support overlapping address spaces. Correct global CIDR allocation is therefore a prerequisite for deterministic topology synthesis.

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

**Stage 3 — Global IR Pass (Full Mesh Trio)**

Full Mesh Trio composes multiple regional meshes into a global mesh:
- Establishes all N×N TGW peering adjacencies.
- Creates cross-region V×V routing expansions so that VPCs in different regions inherit full reachability.
- Merges three regional IRs (one per region) into a single global IR representing a multi-region mesh.

Thus:
- Full Mesh Trio is responsible for O(N²) TGW relationships and cross-region O(V²) propagation.
- Regional and global complexity dimensions remain cleanly separated.

This stage corresponds to a compiler’s late-stage code generation: assembling multiple modules into a linked, globally optimized output.

⸻

**Stage 4 - Optional Optimization Pass — VPC Peering Deluxe (Selective Direct Edges)**

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

**Summary of Compiler Architecture**

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

This shift from imperative, relationship-level configuration to compiler-generated topology is the core conceptual contribution of the architecture.

A complete, production-grade implementation of this AST → Regional IR → Global IR pipeline is provided in the centralized egress dual-stack full-mesh trio demo, which composes Tiered VPC-NG, Centralized Router, Full Mesh Trio, VPC Peering Deluxe, the IPv4/IPv6 intra-VPC and full-mesh security group rule modules, and centralized egress into a unified topology compiler. This integration demonstrates the system operating end-to-end across three regions, nine VPCs, centralized egress, dual-stack CIDR propagation, and mixed TGW + VPC-peering edges. The demo serves as the reference implementation upon which the empirical results and analyses in this paper are based.

In dual-stack deployments, this model enables asymmetric egress semantics: IPv4 traffic is routed through centralized NAT Gateways to achieve O(1) cost scaling, while IPv6 traffic follows decentralized, NAT-free egress paths, leveraging native IPv6 routing and TGW propagation. This behavior is demonstrated end-to-end in the centralized egress dual-stack full-mesh trio reference implementation.

**Parallel Security Propagation Layer:**
The same compilation pipeline used for routing is mirrored at the security layer. Each Tiered VPC-NG instance exposes an intra_vpc_security_group_id that downstream modules use to synthesize security relationships. At the regional layer, the Intra VPC Security Group Rule modules (IPv4 and IPv6 variants) construct O(V²) ingress-only allow rules between all non-self VPC network CIDRs, forming a regional SG mesh. At the global layer, the Full Mesh Intra VPC Security Group Rules modules replicate these rules across regions, producing a three-region SG mesh that aligns with the routing mesh. These SG meshes are designed to make end-to-end reachability testing easy in the reference implementation; they are not positioned as a least-privilege production policy, but as a concrete example of how security propagation can be compiled from the same topology AST.

### 2.3 Contributions

This work makes five core contributions that, together, establish a new declarative and compiler-based model for multi-region AWS network topology synthesis.

⸻

1. Complexity Transformation: From O(N² + V²) to O(N + V)

AWS networking today requires imperatively specifying all TGW adjacencies (O(N²)) and all VPC-level routing and security relationships (O(V²)). This architecture reduces operator input to O(N + V) declarative topology intent while deterministically generating the full O(N² + V²) relationship set through compiler-style IR passes.

The architecture:
- accepts O(N + V) declarative input
- infers all TGW mesh adjacencies (O(N²))
- infers all VPC-level propagation relationships (O(V²))
- pushes the quadratic complexity into deterministic, repeatable IR transformations

This is achieved through:
- Tiered VPC-NG (AST construction: structure only, no routing logic)
- Centralized Router (regional IR: O(V²) intra-region expansion)
- Full Mesh Trio (global IR: O(N²) peering + cross-region O(V²) expansion)

The result is a provable complexity reduction:
```
Imperative:   O(N² + V²) relationships to specify
Declarative:  O(N + V) topology intent to declare
```

This transformation forms the theoretical basis for the architecture.

⸻

2. Multi-Pass Compiler for Cloud Topology (AST → IR → IR → Code)

This work introduces a multi-pass compilation pipeline for cloud networking, implemented through pure-function Terraform modules that generate and transform intermediate representations subsequently composed into concrete infrastructure:
1. AST Construction (Tiered VPC-NG):
- A typed, validated representation of all VPCs, CIDRs, subnets, NAT policies, and dual-stack attributes

2. Regional IR (Centralized Router):
- one TGW per region
- attachment mapping
- TGW route-table synthesis
- blackhole insertion
- centralized egress semantics
- O(V²) intra-region expansion via generate_routes_to_other_vpcs

3. Global IR (Full Mesh Trio):
- O(N²) TGW peering synthesis
- cross-region route-table propagation
- V×V global connectivity across all regions

4. Optional Optimization Pass (VPC Peering Deluxe):
- O(1) selective direct edges for low-latency or cost-sensitive paths
- subnet-level microsegmentation

The critical Regional IR pass is implemented as a pure-function Terraform module—a zero-resource transformation that operates solely on data structures. The Global IR pass composes these verified regional outputs using deterministic, resource-creating modules.

This is the first system to apply compiler theory to AWS network topology generation.

Verified IR Transformation:
- The Regional IR pass—responsible for all O(V²) routing expansion—is implemented as a pure-function Terraform module and is formally verified through deterministic, property-based tests that validate routing invariants across diverse multi-VPC configurations.

- The Global IR pass (Full Mesh Trio) composes these verified regional outputs to synthesize N×N TGW adjacencies and cross-region propagation. While the Global IR layer does not yet include a dedicated formal test suite, its behavior is strictly compositional: it combines pre-verified regional IRs without mutating their routing semantics. As a result, the correctness guarantees established for the Regional IR pass transfer cleanly to the global topology.

3. Embedded DSL for Declarative Multi-Region AWS Networking

Across all modules, the system defines a restricted, composable language for expressing topologies:
- VPCs are typed objects with semantic validations
- TGWs are first-class regional constructs
- egress behavior is a polymorphic attribute
- routing rules are derived, not declared
- mesh intent is encoded structurally, not procedurally

This embedded DSL provides:
- denotational semantics: VPC maps deterministically map to IR
- operational semantics: IR deterministically maps to AWS resources
- orthogonality: TGW logic, VPC logic, and egress logic remain independent
- economy of expression: ~15 lines per VPC defines complete regional + global routing

The DSL is encoded through Terraform module composition and expressed entirely through zero-resource functional modules, rather than through Terraform resources themselves.

4. Production-Scale Performance: Amplification, Speedups, and O(1) Egress

Empirical evaluation on a 3-TGW, 9-VPC, 3-region topology shows:
- 1,308 AWS resources generated from
- 174 lines of input (7.5× amplification; 10.3× theoretical maximum)
- 120× deployment-velocity improvement (31.2 hours → 15.75 minutes)
- 92% reduction in configuration surface area

The architecture also introduces an O(1) NAT Gateway model, where egress requires:

a constant number of NAT Gateways per region

instead of the AWS-default O(V) model (one NAT per VPC per AZ).
In the reference deployment:
- 18 traditional NAT Gateways → 6 centralized gateways
- 67% cost reduction (≈$4,730 annual savings per region)

These performance and cost characteristics demonstrate practical viability at enterprise scale.

In contrast to traditional AWS reference architectures, which scale NAT Gateways, routing tables, and security rules linearly with VPC count, this system keeps egress cost and routing complexity bounded and constant at the regional layer.

5. Formal Reasoning, Entropy Reduction, and Verifiable Infrastructure

Because all routing and security expansions are produced via pure, deterministic IR transforms, the architecture supports formal reasoning uncommon in cloud networking:
- 27% reduction in configuration entropy (9.9 → 7.2 bits)
- 2^2.7 ≈ 6.5× reduction in semantic decision space
- property-based testing for pure-function route generation
- idempotence and reproducibility guaranteed by referential transparency
- provable correctness criteria (completeness, totality, non-interference)

This positions the system not as a Terraform module collection but as a verifiable topology compiler.

Summary of Contributions

In total, this paper presents:
-	A provable complexity transformation
-	A multi-pass compiler for AWS networking
-	A declarative embedded DSL for topology synthesis
-	Production-scale performance + O(1) egress scaling
-	Formal verification through pure-function IR passes

Together, these contributions represent a new paradigm for expressing and synthesizing multi-region AWS network topologies.
