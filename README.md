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

## TNT Architecture!
[Terraform Networking Trifecta Demo](https://github.com/JudeQuintana/terraform-main/tree/main/networking_trifecta_demo)
 - Compose a Transit Gateway hub spoke topology using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng) and [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router) modules.
 - Validate connectivity with EC2 instances.

## Super Router!
[Super Router Demo](https://github.com/JudeQuintana/terraform-main/tree/main/super_router_demo)
 - Compose a cross-region and inter-region Transit Gateway decentralized hub spoke topology from existing hub spokes using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router), and [Super Router](https://github.com/JudeQuintana/terraform-aws-super-router) modules.
 - Validate connectivity with AWS Route Analyzer.

## Full Mesh Trio!
[Full Mesh Trio Demo](https://github.com/JudeQuintana/terraform-main/tree/main/full_mesh_trio_demo)
 - Compose a Full Mesh Transit Gateway topology across 3 regions from existing hub spokes using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router) and [Full Mesh Trio](https://github.com/JudeQuintana/terraform-aws-full-mesh-trio) modules.
 - Includes a VPC peering cross region and inter region examples within a full mesh configuration for high traffic workloads to save on cost instead of going through the TGW using the [VPC Peering Deluxe](https://github.com/JudeQuintana/terraform-aws-vpc-peering-deluxe) module.
 - Validate connectivity with AWS Route Analyzer.

## Mega Mesh!
[Mega Mesh Demo](https://github.com/JudeQuintana/terraform-main/tree/main/mega_mesh_demo)
 - Compose a Full Mesh Transit Gateway topology across 10 regions from existing hub spokes using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router) and [Mega Mesh](https://github.com/JudeQuintana/terraform-aws-mega-mesh) modules.
 - Validate connectivity with AWS Route Analyzer.

---
Notes:
 - All modules are first developed in the [terraform-modules](https://github.com/JudeQuintana/terraform-modules) repo.
 - Sometimes I'll blog about ideas at [jq1.io](https:/jq1.io).
 - The most useful modules are [published](https://registry.terraform.io/namespaces/JudeQuintana) to the Public Terraform Registry.
 - All demos include an example of generating security group rules for VPCs for each TGW configuration.
   - [Intra VPC Security Group Rule](https://github.com/JudeQuintana/terraform-aws-intra-vpc-security-group-rule)
   - [Super Intra VPC Security Group Rules](https://github.com/JudeQuintana/terraform-aws-super-intra-vpc-security-group-rules)
   - [Full Mesh Intra VPC Security Group Rules](https://github.com/JudeQuintana/terraform-aws-full-mesh-intra-vpc-security-group-rules)
   - TODO: Mega Mesh Intra VPC Security Group Rules
   - Centralized Router is an implementation of the [AWS Centralized Router concept](https://docs.aws.amazon.com/vpc/latest/tgw/transit-gateway-centralized-router.html) but without VPN Gateway or Direct Connect.
  - Available AZs (a,b,c etc) in a region are different per AWS account (ie. your us-west-2a is not the same AZ as my us-west-2a)
    so it's possible you'll need to change the AZ letter for a VPC if the provider saying it's not available for the region.
 - There is no overlapping CIDR detection cross region or intra region so it's important that the VPC's network and subnet CIDRs are allocated correctly.
 - Demos can be used with AWS 4.x and 5.x providers but there will be a warning about a `aws_eip` attribute deprecation in the 5.x provider for Tiered VPC-NG.
   - Will still work when enabling NATGW for a given AZ.
   - It's possible you might need to run `terraform init -upgrade` in each demo to upgrade to the AWS 5.x provider if you were previously running the demo using the 4.x provider.
   - Or run `terraform get -update` to refresh module code.
 - Visual inspiration to spice up the concept:
   - https://twitter.com/MAKIO135/status/1378469836305666055
   - https://twitter.com/MAKIO135/status/1380634991818911746
   - https://twitter.com/MAKIO135/status/1379931304863657984
   - https://twitter.com/MAKIO135/status/1404543066724253699
   - https://twitter.com/MAKIO135/status/1368340867803660289
