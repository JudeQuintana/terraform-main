# Full Mesh Trio Demo
- [Full Mesh Trio](https://github.com/JudeQuintana/terraform-aws-full-mesh-trio) module takes in three Centralized Routers and compose a full mesh peering (cross region) configuration between them. It will then generate routes for all tgws and their respsective VPCs.

Full Mesh Trio module builds peering links (red) between existing hub spoke tgws (Centralized Routers) and adds proper routes to all TGWs and their attached VPCs, etc.

The resulting architecture is a full mesh configurion between 3 cross-region hub spoke topologies:
![full-mesh-trio](https://jq1-io.s3.amazonaws.com/full-mesh-trio/full-mesh-trio.png)

Related articles:
- Blog Post in coming soon...

Demo:
- Pre-requisite: AWS account, may need to increase your VPC and or TGW quota for
  each us-east-1, us-east-2, us-west-2 depending on how many you currently have.
This demo will be creating 6 VPCs (2 in each region) and 3 TGWs (1 in each region)

It begins:
 - `terraform init`

Apply Tiered-VPCs (must exist before Centralized Routers):
 - `terraform apply -target module.vpcs_use1 -target module.vpcs_use2 -target module.vpcs_usw2`

Apply Centralized Routers (must exist before Full Mesh Trio):
 - `terraform apply -target module.centralized_router_use1 -target module.centralized_router_use2 -target module.centralized_router_usw2`

Apply Full Mesh Trio:
 - `terraform apply -target module.full_mesh_trio`

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

