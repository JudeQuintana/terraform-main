```
     ____.             ________        ________
    |    |____  ___.__.\_____  \       \_____  \   ____   ____
    |    \__  \<   |  | /  / \  \       /   |   \ /    \_/ __ \
/\__|    |/ __ \\___  |/   \_/.  \     /    |    \   |  \  ___/
\________(____  / ____|\_____\ \_/_____\_______  /___|  /\___  >
              \/\/            \__>_____/       \/     \/     \/

--=[ PrEsENtZ ]=--

--=[ AwS CLouD NeTWoRkiNg SuiTE 3000 ]=--

--=[ #StayUp ]=--
```

## NEW Dual Stack TNT Architecture!
[Dual Stack Terraform Networking Trifecta Demo](https://github.com/JudeQuintana/terraform-main/tree/main/dual_stack_networking_trifecta_demo)
 - Compose a hub and spoke Transit Gateway topology using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng) (at `v1.0.2`) and [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router) (at `v1.0.2`) modules.
 - Requires IPAM Pools for IPv4 and IPv6 cidrs.
 - Validate connectivity with EC2 instances.

## TNT Architecture!
[Terraform Networking Trifecta Demo](https://github.com/JudeQuintana/terraform-main/tree/main/networking_trifecta_demo)
 - Compose a hub and spoke Transit Gateway topology using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng) (at `v1.0.1`) and [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router) (at `v1.0.1`) modules.
 - IPv4 only (no IPAM).
 - Validate connectivity with EC2 instances.

## Super Router!
[Super Router Demo](https://github.com/JudeQuintana/terraform-main/tree/main/super_router_demo)
 - Compose a decentralized hub and spoke Transit Gateway topology using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng) (at `v1.0.1`), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router) (at `v1.0.1`), and [Super Router](https://github.com/JudeQuintana/terraform-aws-super-router) (at `v1.0.0`) modules.
 - IPv4 only (no IPAM).
 - Validate connectivity with AWS Route Analyzer.

## Full Mesh Trio!
[Full Mesh Trio Demo](https://github.com/JudeQuintana/terraform-main/tree/main/full_mesh_trio_demo)
 - Compose a Full Mesh Transit Gateway topology across 3 regions using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng) (at `v1.0.1`), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router) (at `v1.0.1`) and [Full Mesh Trio](https://github.com/JudeQuintana/terraform-aws-full-mesh-trio) (at `v1.0.0`) modules.
 - Includes an VPC peering examples within a full mesh configuration for high traffic workloads to save on cost using the [VPC Peering Deluxe](https://github.com/JudeQuintana/terraform-aws-vpc-peering-deluxe) module.
 - IPv4 only (no IPAM).
 - Validate connectivity with AWS Route Analyzer.

## Mega Mesh!
[Mega Mesh Demo](https://github.com/JudeQuintana/terraform-main/tree/main/mega_mesh_demo)
 - Compose a Full Mesh Transit Gateway topology across 10 regions using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng) (at `v1.0.1`), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router) (at `v1.0.1`) and [Mega Mesh](https://github.com/JudeQuintana/terraform-aws-mega-mesh) (at `v1.0.0`) modules.
 - IPv4 only (no IPAM).
 - Validate connectivity with AWS Route Analyzer.

---
Notes:
 - Sometimes I'll blog about ideas at [jq1.io](https://jq1.io).
 - All modules are first developed in the [terraform-modules](https://github.com/JudeQuintana/terraform-modules) repo.
 - The most useful modules are [published](https://registry.terraform.io/namespaces/JudeQuintana) to the Public Terraform Registry.
 - All demos include an example of generating security group rules for inter-region and cross-region VPCs for each TGW configuration.
   - [Intra VPC Security Group Rule](https://github.com/JudeQuintana/terraform-aws-intra-vpc-security-group-rule) (IPv4 only)
   - [Super Intra VPC Security Group Rules](https://github.com/JudeQuintana/terraform-aws-super-intra-vpc-security-group-rules) (IPv4 only)
   - [Full Mesh Intra VPC Security Group Rules](https://github.com/JudeQuintana/terraform-aws-full-mesh-intra-vpc-security-group-rules) (IPv4 only)
   - New [IPv6 Intra VPC Security Group Rule](https://github.com/JudeQuintana/terraform-aws-ipv6-intra-vpc-security-group-rule) (IPv6 only, for use with dual stack VPCs)
   - TODO: Mega Mesh Intra VPC Security Group Rules
 - The Centralized Router module is an implementation of the [AWS Centralized Router concept](https://docs.aws.amazon.com/vpc/latest/tgw/transit-gateway-centralized-router.html) but without VPN Gateway or Direct Connect, only VPCs.
  - Available AZs (a,b,c etc) in a region are different per AWS account (ie. your us-west-2a is not the same AZ as my us-west-2a)
    so it's possible you'll need to change the AZ letter for a VPC if the provider is saying it's not available for the region.
 - There is no overlapping CIDR detection inter-region or cross-region so it's important that the VPC's network and subnet CIDRs are allocated correctly.

Updates:
 - New dual stack versions of Tiered VPC-NG and Centralized Router at `v1.0.2`
   - Requires IPAM Pools for IPv4 and IPv6 cidrs. (Previous versions were IPv4 only.)
   - New `v1.0.1` version for IPv4 Intra VPC Security Group Rule module is updated to provide support for IPv4 secondary cidrs.
   - New `v1.0.0` IPv6 Intra VPC Security Group Rule module.
   - New Dual Stack Terraform Networking Trifecta Demo.
   - Now that the base IPv4 networking modules also supports IPv4 secondary cidrs and IPv6 cidrs with auto routing, I plan to build dual stack implementations for Full Mesh Trio, VPC peering deluxe, IPv6 version of Full Mesh Intra VPC Security Group Rules and then, eventually, Mega Mesh. Looks like it's going be a long haul.

 - Demos have been updated to use Tiered VPC-NG and Centralized Router
   at `v1.0.1`.
   - This version now only uses the AWS 5.x provider.
   - Demonstrates using private subnets only, public subnets only
     or both using `special = true` on either subnet per AZ.
   - Build a NATGW for all private subnets by adding `natgw = true` to
     any public subnet.
   - Is still compatible with all other modules at `v1.0.0` (super
     router, full mesh trio, mega mesh etc)
   - No provided move blocks for migration path to Tiered VPC-NG `v1.0.1` so it's best to start fresh.
   - It's possible you might need to run `terraform init -upgrade` in each demo to upgrade to the latest 5.x provider.
   - Or run `terraform get -update` to refresh module code.

 - Visual inspiration to spice up the concept:
   - https://twitter.com/MAKIO135/status/1378469836305666055
   - https://twitter.com/MAKIO135/status/1380634991818911746
   - https://twitter.com/MAKIO135/status/1379931304863657984
   - https://twitter.com/MAKIO135/status/1404543066724253699
   - https://twitter.com/MAKIO135/status/1368340867803660289
