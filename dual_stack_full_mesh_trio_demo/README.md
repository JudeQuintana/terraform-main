# Full Mesh Trio Demo
[Full Mesh Trio module](https://github.com/JudeQuintana/terraform-aws-full-mesh-trio) takes in three Centralized Routers and composes a cross-region TGW full mesh topology from existing hub spokes in AWS. It peers and generates routes for TGWs and their respective VPCs.

The resulting architecture is a full mesh between 3 cross-region hub spoke topologies:
![full-mesh-trio](https://jq1-io.s3.amazonaws.com/full-mesh-trio/full-mesh-trio-new.png)

---

### Bonus Update!

[VPC Peering Deluxe module](https://github.com/JudeQuintana/terraform-aws-vpc-peering-deluxe):
 - VPC Peering Deluxe module will create appropriate routes for all subnets in each cross region Tiered VPC-NG by default.
 - The module also works for inter region VPCs.
 - Specific subnet cidrs can be selected (instead of default behavior) to route across the VPC peering connection via only_route_subnet_cidrs variable list.
 - Additional option to allow remote dns resolution too.
 - Can be used in tandem with Centralized Router, Super Router, Full Mesh Trio and Mega Mesh for workloads that transfer lots of data to save on cost instead of via TGW (especially inter region).

Important:
 - If you've ran this demo before then it's possible that you'll need to run `terraform get -update` to get the updated Tiered VPC-NG outputs needed for VPC Peering Deluxe.

cross region Full mesh with cross region and inter region VPC peering:
![full-mesh-trio-with-vpc-peering](https://jq1-io.s3.amazonaws.com/full-mesh-trio/full-mesh-trio-with-two-vpc-peering-examples.png)

---

Related articles:
- Blog Post coming soon...

Demo:
- Pre-requisite: AWS account, may need to increase your VPC and or TGW quota for
  each us-east-1, us-east-2, us-west-2 depending on how many you currently have.
This demo will be creating 6 VPCs (2 in each region) and 3 TGWs (1 in each region)

1. It begins:
  - `terraform init`

2. Apply Tiered-VPCs (must exist before Centralized Routers, VPC Peering Deluxe and Full Mesh Intra VPC Security Group Rules):
  - `terraform apply -target module.vpcs_use1 -target module.vpcs_use2 -target module.vpcs_usw2`

3. Apply Full Mesh Intra VPC Security Group Rules (will auto apply it's dependent modules Intra Security Group Rules for each region) for EC2 access across VPC regions (ie ssh and ping) for VPCs in a TGW Full Mesh configuration.
  - `terraform apply -target module.full_mesh_intra_vpc_security_group_rules`

4. Apply VPC Peering Deluxe and Centralized Routers:
  - `terraform apply -target module.vpc_peering_deluxe_use1_general2_to_use2_cicd1 -target module.vpc_peering_deluxe_usw2_app1_to_usw2_general1 -target module.centralized_router_use1 -target module.centralized_router_use2 -target module.centralized_router_usw2`

5. Apply Full Mesh Trio:
  - `terraform apply -target module.full_mesh_trio`

Note: You can combine steps 3 though 5 with `terraform apply`.

Full Mesh Trio is now complete!

Note: If we were using this in Terraform Cloud then it would be best for each of the module applys above to be in their own separate networking workspace with triggers. For example, if a VPC or AZ is added in it's own VPC workspace then apply and trigger the centralized router workspace to build routes, then trigger full mesh trio)

Routing and peering validation with AWS Route Analyzer:
- Go to [AWS Network Manager](https://us-west-2.console.aws.amazon.com/networkmanager/home?region=us-east-1#/networks) (free to use)
  - Create global network -> `next`
    - UNCHECK `Add core network in your global network` or you will be billed extra -> `next`
  - Select new global network -> go to `Transit Gateways` -> `Register
    Transit Gateway` -> Select TGWs -> `Register Transit Gateway` -> wait until all states say `Available`
  - Go to `Transit gateway network` -> `Route Analyzer`
    - Cross-Region Test 1 (use1a to use2c)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-mystique-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app2-use1 <-> TEST-centralized-router-mystique-use1` (VPC)
        - IP Address: `10.0.4.70` (`haproxy1` public subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-magento-use2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-infra1-use2 <-> TEST-centralized-router-magneto-use2` (VPC)
        - IP Address: `172.16.16.10` (`jenkins2` private subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Cross-Region Test 2 (use2a to usw2a)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-magneto-use2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-cicd1-use2 <-> TEST-centralized-router-magneto-use2` (VPC)
        - IP Address: `172.16.6.8` (`jenkins1` private subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-arch-angel-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app1-usw2 <-> TEST-centralized-router-arch-angel-usw2` (VPC)
        - IP Address: `10.0.19.9` (`random1` public subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Cross-Region Test 3 (usw2c to use1c)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-arch-angel-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-general1-usw2 <-> TEST-centralized-router-arch-angel-usw2` (VPC)
        - IP Address: `192.168.16.3` (`experiment1` private subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-mystique-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-general2-use1 <-> TEST-centralized-router-mystique-use1` (VPC)
        - IP Address: `192.168.11.4` (`experiment2` private subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
Several other routes can be validated, try them out!

Tear down:
 - `terraform destroy`

