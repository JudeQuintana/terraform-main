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
 - Compose a cross-region Transit Gateway full mesh topology from existing hub spokes using [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-aws-tiered-vpc-ng), [Centralized Router](https://github.com/JudeQuintana/terraform-aws-centralized-router) and [Full Mesh Trio](https://github.com/JudeQuintana/terraform-aws-full-mesh-trio) modules.
 - Includes a VPC peering example within a full mesh configuration for high traffic workloads to save on cost instead of going through the TGW using the [VPC Peering Deluxe](https://github.com/JudeQuintana/terraform-aws-vpc-peering-deluxe) module.
 - Validate connectivity with AWS Route Analyzer.

---
Notes:
 - All modules are first developed in the [terraform-modules](https://github.com/JudeQuintana/terraform-modules) repo.
 - Sometimes I'll blog about ideas at [jq1.io](https:/jq1.io).
 - The most useful modules are [published](https://registry.terraform.io/namespaces/JudeQuintana) to the Public Terraform Registry.
 - All demos include an example of generating security group rules for VPCs for each TGW configuration.
   - [Intra VPC Security Group Rule](https://github.com/JudeQuintana/terraform-aws-intra-vpc-security-group-rule)
   - [Super Intra VPC Secuity Group Rules](https://github.com/JudeQuintana/terraform-aws-super-intra-vpc-security-group-rules)
   - [Full Mesh Intra VPC Secuity Group Rules](https://github.com/JudeQuintana/terraform-aws-full-mesh-intra-vpc-security-group-rules)
 - There is no overlapping CIDR detection across regions so it's important that the VPC's network and subnet CIDRs are allocated correctly.
 - Demos can be used with AWS 4.x and 5.x providers but there will be a warning about a `aws_eip` attribute deprecation for Tiered VPC-NG for 5.x. Should still work when enabling NATGW for a given AZ.
