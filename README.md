```
     ____.             ________        ________
    |    |____  ___.__.\_____  \       \_____  \   ____   ____
    |    \__  \<   |  | /  / \  \       /   |   \ /    \_/ __ \
/\__|    |/ __ \\___  |/   \_/.  \     /    |    \   |  \  ___/
\________(____  / ____|\_____\ \_/_____\_______  /___|  /\___  >
              \/\/            \__>_____/       \/     \/     \/

--=[ PrEsENtZ ]=--

--=[ AwS CLouD NeTWoRkiNg SuiTE 3000 ]=--

--=[ Build and scale cloud network topologies from base components in AWS and Terraform ]=--

--=[ #StayUp ]=--
```
## NEW Routing Policy Language
- The topology compiler now includes a [routing policy language](https://github.com/JudeQuintana/terraform-main/tree/main/docs/routing-policy-language.md) that shapes VPC reachability at compile time through four primitives with fixed precedence: `deny > allow > segments > default`.
- A single policy declaration controls both IPv4 and IPv6 route generation. The language is scope-invariant, the same evaluation works across Centralized Router (Regional IR), Full Mesh Trio (Global IR), and Super Router (Domain IR).
- Policy compiles to VPC route table entries (the policy edge). The TGW forwarding plane stays untouched. `terraform plan` shows the complete reachability proof before apply.
- Here's the related [blog post](https://jq1.io/posts/routing_policy_language/).
- See the [Centralized Egress Dual Stack Full Mesh Trio Demo](https://github.com/JudeQuintana/terraform-main/tree/main/centralized_egress_dual_stack_full_mesh_trio_demo) for working examples with segmentation and deny rules.
- The generate routes function with the new policy routing has been moved out of Centralized Router into its own module [Generate Routes to Other VPCs](https://github.com/JudeQuintana/terraform-aws-generate-routes-to-other-vpcs/).

## NEW White Paper (WIP)
- What began as a modular Terraform experiment evolved into a full compiler-style architecture for AWS networking. The system transforms a declarative map of VPCs into complete multi-region Transit Gateway mesh configurations, performing automatic adjacency synthesis, route expansion, and deterministic cross-region propagation.
- The [white paper](https://github.com/JudeQuintana/terraform-main/tree/main/docs/WHITEPAPER.md) documents the underlying model, a provable O(N² + V²) → O(N + V) reduction alongside empirical validation across multi-region deployments and is currently a work in progress.

## NEW Super Router Revamped!
[Super Router Revamped Demo](https://github.com/JudeQuintana/terraform-main/tree/main/super_router_revamped_demo)
 - Compose a decentralized hub and spoke Transit Gateway with full routing semantic coverage using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng/tree/v1.0.7) (at `v1.0.7`), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router/tree/v1.1.0) (at `v1.1.0`), [Super Router](https://github.com/JudeQuintana/terraform-aws-super-router/tree/v2.0.0) (at `v2.0.0`), and [Generate Routes to Other VPCs](https://github.com/JudeQuintana/terraform-aws-generate-routes-to-other-vpcs/tree/v1.1.0) (at `v1.1.0`) modules.
 - Includes VPC peering examples within a full mesh configuration used for high traffic workloads to save on cost using the [VPC Peering Deluxe](https://github.com/JudeQuintana/terraform-aws-vpc-peering-deluxe/tree/v1.0.1) module (at `v1.0.1`).
 - Requires IPAM Pools for IPv4 and IPv6 cidrs (dual stack).
 - Incudes routing policy.
 - Validate TGW connectivity with AWS Route Analyzer.
 - Super Router now provides complete semantic coverage of the AWS TGW routing domain:
   - Expressive: handles all CIDR and address-family combinations
   - Compositional: hierarchical domains compose cleanly
   - Complete: covers the full AWS TGW routing semantic space

## NEW Centralized Egress Dual Stack Full Mesh Trio!
[Centralized Egress Dual Stack Full Mesh Trio Demo](https://github.com/JudeQuintana/terraform-main/tree/main/centralized_egress_dual_stack_full_mesh_trio_demo)
 - Compose a Centralized IPv4 Egress and Decentralized IPv6 Egress within a Dual Stack Full Mesh Topology across 3 regions using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng/tree/v1.0.7) (at `v1.0.7`), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router/tree/v1.1.0) (at `v1.1.0`), [Full Mesh Trio](https://github.com/JudeQuintana/terraform-aws-full-mesh-trio/tree/v2.0.0) (at `v2.0.0`), and [Generate Routes to Other VPCs](https://github.com/JudeQuintana/terraform-aws-generate-routes-to-other-vpcs/tree/v1.1.0) (at `v1.1.0`) modules.
 - Includes VPC peering examples within a full mesh configuration used for high traffic workloads to save on cost using the [VPC Peering Deluxe](https://github.com/JudeQuintana/terraform-aws-vpc-peering-deluxe/tree/v1.0.1) module (at `v1.0.1`).
 - Requires IPAM Pools for IPv4 and IPv6 cidrs.
 - Incudes routing policy.
 - Validate connectivity with Route Analyzer.

## Dual Stack Full Mesh Trio!
[Dual Stack Full Mesh Trio Demo](https://github.com/JudeQuintana/terraform-main/tree/main/dual_stack_full_mesh_trio_demo)
 - Compose a dual stack Full Mesh Transit Gateway across 3 regions using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng/tree/v1.0.7) (at `v1.0.7`), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router/tree/v1.1.0) (at `v1.1.0`), [Full Mesh Trio](https://github.com/JudeQuintana/terraform-aws-full-mesh-trio/tree/v2.0.0) (at `v2.0.0`), and [Generate Routes to Other VPCs](https://github.com/JudeQuintana/terraform-aws-generate-routes-to-other-vpcs/tree/v1.1.0) (at `v1.1.0`) modules.
 - Includes VPC peering examples within a full mesh configuration used for high traffic workloads to save on cost using the [VPC Peering Deluxe](https://github.com/JudeQuintana/terraform-aws-vpc-peering-deluxe/tree/v1.0.1) module (at `v1.0.1`).
 - Requires IPAM Pools for IPv4 and IPv6 cidrs.
 - Incudes routing policy.
 - Validate TGW connectivity with Route Analyzer.

## Dual Stack TNT Architecture!
[Dual Stack Terraform Networking Trifecta Demo](https://github.com/JudeQuintana/terraform-main/tree/main/dual_stack_networking_trifecta_demo)
 - Compose a dual stack hub and spoke Transit Gateway using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng/tree/v1.0.7) (at `v1.0.7`), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router/tree/v1.1.0) (at `v1.1.0`), and [Generate Routes to Other VPCs](https://github.com/JudeQuintana/terraform-aws-generate-routes-to-other-vpcs/tree/v1.1.0) (at `v1.1.0`) modules.
 - Requires IPAM Pools for IPv4 and IPv6 cidrs.
 - Validate intra VPC connectivity with EC2 instances.
 - Incudes routing policy.

## Super Router!
[Super Router Demo](https://github.com/JudeQuintana/terraform-main/tree/main/super_router_demo)
 - Compose a decentralized hub and spoke Transit Gateway using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng/tree/v1.0.1) (at `v1.0.1`), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router/tree/v1.0.1) (at `v1.0.1`), and [Super Router](https://github.com/JudeQuintana/terraform-aws-super-router/tree/v1.0.0) (at `v1.0.0`) modules.
 - IPv4 only (no IPAM).
 - No routing policy (default full mesh).
 - Validate TGW connectivity with AWS Route Analyzer.

## Mega Mesh!
[Mega Mesh Demo](https://github.com/JudeQuintana/terraform-main/tree/main/mega_mesh_demo)
 - Compose a Full Mesh Transit Gateway across 10 regions using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng/tree/v1.0.1) (at `v1.0.1`), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router/tree/v1.0.1) (at `v1.0.1`) and [Mega Mesh](https://github.com/JudeQuintana/terraform-aws-mega-mesh/tree/v1.0.0) (at `v1.0.0`) modules.
 - IPv4 only (no IPAM).
 - No routing policy (default full mesh).
 - Validate connectivity with AWS Route Analyzer.

## Full Mesh Trio!
[Full Mesh Trio Demo](https://github.com/JudeQuintana/terraform-main/tree/main/full_mesh_trio_demo)
 - Compose a Full Mesh Transit Gateway across 3 regions using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng/v1.0.1) (at `v1.0.1`), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router/v1.0.1) (at `v1.0.1`) and [Full Mesh Trio](https://github.com/JudeQuintana/terraform-aws-full-mesh-trio/tree/v1.0.0) (at `v1.0.0`) modules.
 - Includes VPC peering examples within a full mesh configuration for high traffic workloads to save on cost for intra-region using the [VPC Peering Deluxe](https://github.com/JudeQuintana/terraform-aws-vpc-peering-deluxe/tree/v1.0.0) module (at `v1.0.0`).
 - IPv4 only (no IPAM).
 - No routing policy (default full mesh).
 - Validate TGW connectivity with AWS Route Analyzer.

## TNT Architecture!
[Terraform Networking Trifecta Demo](https://github.com/JudeQuintana/terraform-main/tree/main/networking_trifecta_demo)
 - Compose a hub and spoke Transit Gateway using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng/tree/v1.0.1) (at `v1.0.1`) and [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router/tree/v1.0.1) (at `v1.0.1`) modules.
 - IPv4 only (no IPAM).
 - No routing policy (default full mesh).
 - Validate intra VPC connectivity with EC2 instances.

---
### Useful Tools
- [IPv4 Subnet Calculator](https://visualsubnetcalc.com/#)
- [IPv6 Subnet Calculator](https://subnettingpractice.com/ipv6-subnet-calculator.html)
- `brew install ipcalc`

---
### Notes
- Sometimes I'll blog about ideas at [jq1.io](https://jq1.io).
- All modules are first developed in the [terraform-modules](https://github.com/JudeQuintana/terraform-modules) repo.
- The most useful modules are [published](https://registry.terraform.io/namespaces/JudeQuintana) to the Public Terraform Registry.
- All demos include an example of generating security group rules for intra-region and cross-region VPCs for each TGW configuration.
  - [Intra VPC Security Group Rule](https://github.com/JudeQuintana/terraform-aws-intra-vpc-security-group-rule) (IPv4 only)
  - [Super Intra VPC Security Group Rules](https://github.com/JudeQuintana/terraform-aws-super-intra-vpc-security-group-rules) (IPv4 only)
  - [Full Mesh Intra VPC Security Group Rules](https://github.com/JudeQuintana/terraform-aws-full-mesh-intra-vpc-security-group-rules) (IPv4 only)
  - [IPv6 Intra VPC Security Group Rule](https://github.com/JudeQuintana/terraform-aws-ipv6-intra-vpc-security-group-rule) (IPv6 only, for use with dual stack VPCs)
  - [IPv6 Full Mesh Intra VPC Security Group Rules](https://github.com/JudeQuintana/terraform-aws-ipv6-full-mesh-intra-vpc-security-group-rules) (IPv6 only, for use with dual stack VPCs)
  - NEW [IPv6 Super Intra VPC Security Group Rules](https://github.com/JudeQuintana/terraform-aws-ipv6-super-intra-vpc-security-group-rules) (IPv6 only, for use with dual stack VPCs)
  - TODO: Mega Mesh Intra VPC Security Group Rules
- Included S3 Gateway examples via VPC Endpoint.
- The Centralized Router module is an implementation of both `AWS Centralized Router` and `Centralized outbound routing to the internet` [concepts](https://docs.aws.amazon.com/vpc/latest/tgw/transit-gateway-centralized-router.html) and but without VPN Gateway or Direct Connect, only VPCs.
 - Available AZs (a,b,c etc) in a region are different per AWS account (ie. your us-west-2a is not the same AZ as my us-west-2a)
    so it's possible you'll need to change the AZ letter for a VPC if the provider is saying it's not available for the region.
- There is no overlapping CIDR detection intra-region or cross-region so it's important that the VPC's network and subnet CIDRs are allocated correctly.
- The AWS provider is updated from time to time so you may need to run `terraform init -upgrade` if you've ran init with a previous provider version.
