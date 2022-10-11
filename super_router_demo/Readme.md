Original Blog Post: [Super Powered, Super Sharp, Super Router!](https://jq1.io/posts/super_router/)

This is a follow up to the [generating routes post](https://jq1.io/posts/generating_routes/).

See the new [$init super refactor](https://jq1.io/posts/init_super_refactor/) blog post for moar deets!

Demo:
- Pre-requisite: AWS account, may need to increase your VPC and or TGW quota for
  each us-east-1 and us-west-2 depending on how many you currently have.
This demo will be creating 4 more VPCs in each region (8 total) and 3 TGWs in each region (6 total)
- [Super Router](https://github.com/JudeQuintana/terraform-modules/tree/master/networking/tgw_super_router_for_tgw_centralized_router) module provides both intra-region and cross-region peering and routing for Centralized Routers and Tiered VPCs (same AWS account only, no cross account).

- Architecture diagrams, lol:
  - intra-region:
    - `public subnet usw2a in app vpc <-> usw2 centralized router 1 <-> usw2 super router <-> usw2 centralized router 2 <-> private subnet usw2c in general vpc`
    - `private subnet use1a in app vpc <-> use1 centralized router 1 <-> use1 super router <-> use1 centralized router 2 <-> public subnet use1c in infra vpc`
  - cross-region:
    - `public subnet usw2a in app vpc <-> usw2 centralized router 1 <-> usw2 super router <-> use1 super router <-> use1 centralized router 1 <-> private subnet use1c in general vpc`

Resulting Architecture:
![super-router](https://jq1.io/img/super-refactor-after.png)

it begins:
 - `terraform init`

VPCs MUST be applied first:
 - `terraform apply -target module.vpcs_usw2 -target module.vpcs_usw2_another -target module.vpcs_use1 -target module.vpcs_use1_another`

apply centralized routers:
 - `terraform apply -target module.tgw_centralized_router_usw2 -target module.tgw_centralized_router_usw2_another -target module.tgw_centralized_router_use1 -target module.tgw_centralized_router_use1_another`

apply super router:
 - `terraform apply -target module.tgw_super_router_usw2_to_use1`


Validation with AWS Route Analyzer
- Go to [AWS Network Manager](https://us-west-2.console.aws.amazon.com/networkmanager/home#/networks) (free to use)
  - Create global network -> `next`
    - UNCHECK `Add core network in your global network` or you will be billed extra -> `next`
  - Select new global network -> go to `Transit Gateways` -> `Register
    Transit Gateway` -> Select TGWs -> `Register Transit Gateway` -> wait until all states say `Available`
  - Go to `Transit gateway network` -> `Route Analyzer`
    - Intra-Region Test 1
      - Source:
        - Transit Gateway: Choose Centralized Router in usw2
        - Transit Gateway Attachment: Choose general-usw2 (VPC)
        - IP Address: `192.168.16.7`
      - Destination:
        - Transit Gateway: Choose Centralized Router in usw2
        - Transit Gateway Attachment: Choose cicd-usw2 (VPC)
        - IP Address: `172.16.0.9`
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Intra-Region Test 2
      - Source:
        - Transit Gateway: Choose Centralized Router in use1
        - Transit Gateway Attachment: Choose infra-use1 (VPC)
        - IP Address: `192.168.32.8`
      - Destination:
        - Transit Gateway: Choose Centralized Router in use1
        - Transit Gateway Attachment: Choose app-use1 (VPC)
        - IP Address: `10.0.0.4`
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Cross-Region Test 1
      - Source:
        - Transit Gateway: Choose Centralized Router in usw2
        - Transit Gateway Attachment: Choose app-usw2 (VPC)
        - IP Address: `10.0.19.5`
      - Destination:
        - Transit Gateway: Choose Centralized Router in use1
        - Transit Gateway Attachment: Choose general-use1 (VPC)
        - IP Address: `192.168.10.6`
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Cross-Region Test 2
      - Source:
        - Transit Gateway: Choose Centralized Router in use1
        - Transit Gateway Attachment: Choose cicd-use1 (VPC)
        - IP Address: `10.0.32.3`
      - Destination:
        - Transit Gateway: Choose Centralized Router in usw2
        - Transit Gateway Attachment: Choose infra-usw2 (VPC)
        - IP Address: `172.16.16.6`
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.

Several other routes can be validated, try them out!

Tear down:
 - `terraform destroy`

