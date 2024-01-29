# Mega Mesh
Mega Mesh == (Full Mesh Trio)² + 1

[Mega Mesh module](https://github.com/JudeQuintana/terraform-aws-mega-mesh) takes in 10 Centralized Routers and composes a Full Mesh Transit Gateway topology across 10 regions from existing hub spokes in AWS. It peers and generates routes for TGWs and their respective VPCs.

![mega-mesh](https://jq1-io.s3.amazonaws.com/mega-mesh/ten-full-mesh-tgw.png)

---
Update 1/27/2024:
 - The Terraform Public Registry is mostly* syncing modules correctly again
   so've pointed all module sources back to the public registry.
 - The new Mega Mesh module is now published and all registry modules will continue work together.

---

1. It begins
  - `terraform init`

2. Build VPCs (must exist before centralized routers and mega mesh)
  - `terraform apply -target module.vpcs_use1 -target module.vpcs_usw1 -target module.vpcs_euc1 -target module.vpcs_euw1 -target module.vpcs_apne1 -target module.vpcs_apse1 -target module.vpcs_cac1 -target module.vpcs_sae1 -target module.vpcs_use2 -target module.vpcs_usw2`

3. Build Centralized Routers
  - `terraform apply -target module.centralized_router_use1 -target module.centralized_router_usw1 -target module.centralized_router_euc1 -target module.centralized_router_euw1 -target module.centralized_router_apne1 -target module.centralized_router_apse1 -target module.centralized_router_sae1 -target module.centralized_router_use2 -target module.centralized_router_usw2`

4. Build Mega Mesh
  - `terraform apply -target module.mega_mesh`

Mesh Complete!

Notes:
  - You can combine steps 3 and 4 with `terraform apply`.
  - Add blackhole cidrs on any centralized router via the
    `var.centralized_router.blackhole_cidrs` list to create blackhole routes or aggregate routes.
  - Available AZs (a,b,c etc) in a region are different per AWS account (ie. your us-west-2a is not the same AZ as my us-west-2a)
    so it's possible you'll need to change the AZ letter for a VPC if the provider saying it's not available for the region.

Routing and peering validation with AWS Route Analyzer:
- Go to [AWS Network Manager](https://us-west-2.console.aws.amazon.com/networkmanager/home?region=us-east-1#/networks) (free to use)
  - Create global network -> `next`
    - UNCHECK `Add core network in your global network` or you will be billed extra -> `next`
  - Select new global network -> go to `Transit Gateways` -> `Register
    Transit Gateway` -> Select TGWs -> `Register Transit Gateway` -> wait until all states say `Available`
  - Go to `Transit gateway network` -> `Route Analyzer`
    - Cross-Region Test 1
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-mystique-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app1-use1 <-> TEST-centralized-router-mystique-use1` (VPC)
        - IP Address: `10.0.11.4`
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-gambit-apse1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app6-apse1 <-> TEST-centralized-gambit-apse1` (VPC)
        - IP Address: `10.0.64.7`
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.

    - Cross-Region Test 2
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-gambit-apse1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app6-apse1 <-> TEST-centralized-router-gambit-apse1` (VPC)
        - IP Address: `10.0.70.8`
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-rogue-euw1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-general4-euw1 <-> TEST-centralized-rogue-euw1` (VPC)
        - IP Address: `192.168.38.6`
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.

    - Cross-Region Test 3
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-wolverine-sae1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app8-apse1 <-> TEST-centralized-router-woverine-sae1` (VPC)
        - IP Address: `10.0.128.10`
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-jean-grey-apne1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app5-apne1 <-> TEST-centralized-jean-grey-apne1` (VPC)
        - IP Address: `172.16.40.9`
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.

Several other routes can be validated, try them out!

Tear down:
 - `terraform destroy` (long pause)
