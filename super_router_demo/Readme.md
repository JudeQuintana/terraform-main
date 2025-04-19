# Super Router
Build a decentralized hub and spoke topology both intra-region and cross-region.

Related articles:
- Original Blog Post in [Super Powered, Super Sharp, Super Router!](https://jq1.io/posts/super_router/)
- Fresh new decentralized design in [$init super refactor](https://jq1.io/posts/init_super_refactor/).
- New features means new steez in [Slappin chrome on the WIP](https://jq1.io/posts/slappin_chrome_on_the_wip/)!

Demo:
- Pre-requisite: AWS account, may need to increase your VPC and or TGW quota for
  each us-east-1 and us-west-2 depending on how many you currently have.
This demo will be creating 4 more VPCs in each region (8 total) and 3 TGWs in each region (6 total)
- [Super Router](https://github.com/JudeQuintana/terraform-modules/tree/master/networking/tgw_super_router_for_tgw_centralized_router) module provides both intra-region and cross-region peering and routing for Centralized Routers and Tiered VPCs (same AWS account only, no cross account).

The resulting architecture is a decentralized hub spoke topology:
![super-router-shokunin](https://jq1-io.s3.amazonaws.com/super-router/super-router-shokunin.png)

It begins:
 - `terraform init`

Apply Tiered-VPCs (must exist before Centralized Routers) and S3 Gateways:
 - `terraform apply -target module.vpcs_usw2 -target module.vpcs_another_usw2 -target module.vpcs_use1 -target module.vpcs_another_use1`

Apply Centralized Routers (must exist before Super Router), Intra VPC Security Group Rules and S3 Gateways:
 - `terraform apply -target module.centralized_routers_usw2 -target module.centralized_routers_use1 -target module.intra_vpc_security_group_rules_usw2 -target module.intra_vpc_security_group_rules_use1 -target aws_vpc_endpoint.s3_use1 -target aws_vpc_endpoint.s3_usw2`

Apply Super Router and Super Intra VPC Security Group Rules:
 - `terraform apply -target module.super_router_usw2_to_use1 -target module.super_intra_vpc_security_group_rules_usw2_to_use1`

The Super Router is now complete!

Note: If we were using this in Terraform Cloud then it would be best for each of the module applys above to be in their own separate networking workspace with triggers. For example, if a VPC or AZ is added in it's own VPC workspace then apply and trigger the centralized router workspace to build routes, then trigger a workspace to add to Super Router.)

Routing and peering Validation with AWS Route Analyzer:
- Go to [AWS Network Manager](https://us-west-2.console.aws.amazon.com/networkmanager/home?region=us-east-1#/networks) (free to use)
  - Create global network -> `next`
    - UNCHECK `Add core network in your global network` or you will be billed extra -> `next`
  - Select new global network -> go to `Transit Gateways` -> `Register
    Transit Gateway` -> Select TGWs -> `Register Transit Gateway` -> wait until all states say `Available`
  - Go to `Transit gateway network` -> `Route Analyzer`
    - Intra-Region Test 1 (usw2c to usw2a)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-thunderbird-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-general1-usw2 <-> TEST-centralized-router-thunderbird-usw2` (VPC)
        - IP Address: `192.168.16.7` (`experiment1` private subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-storm-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-cicd1-usw2 <-> TEST-centralized-router-storm-usw2` (VPC)
        - IP Address: `172.16.6.9` (`random1` public subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Intra-Region Test 2 (use1c to use1c)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-bishop-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-infra2-use1 <-> TEST-centralized-router-bishop-use1` (VPC)
        - IP Address: `192.168.32.8` (`db1` private subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-wolverine-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app2-use1 <-> TEST-centralized-router-wolverine-use1` (VPC)
        - IP Address: `10.0.0.4` (`cluster1` private subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Cross-Region Test 1 (usw2a to use1c)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-thunderbird-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app1-usw2 <-> TEST-centralized-router-thunderbird-usw2` (VPC)
        - IP Address: `10.0.19.5` (`random1` public subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-wolverine-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-general2-use1 <-> TEST-centralized-router-wolverine-use1` (VPC)
        - IP Address: `192.168.11.6` (`experiment2` private subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Cross-Region Test 2 (use1a to usw2c)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-bishop-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-cicd2-use1 <-> TEST-centralized-router-bishop-use1` (VPC)
        - IP Address: `10.0.32.3` (`jenkins1` private subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-storm-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-infra1-usw2 <-> TEST-centralized-router-storm-usw2` (VPC)
        - IP Address: `172.16.16.6` (`jenkins2` private subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.

Several other routes can be validated, try them out!

Tear down:
 - `terraform destroy` (long delay to get to yes or no prompt, be patient)

