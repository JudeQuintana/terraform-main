# Super Router Revamped WIP
Build a decentralized hub and spoke topology both intra-region and cross-region.

Refactor is a work in progress:
- [x] Requires IPAM (done)
- [x] Super router refactor for IPv4 network cidrs (works!)
- [x] Added support for IPv4 secondaries (works!)

TODO:
- [x] Support IPv6 and secondaries for super router revamped
- [x] Enable centralized egress per centralized router
- [x] Build IPv6 version of super intra vpc security group rules
- [X] Update IPv6 blackhole cidrs
- [X] Add intra and cross region vpc peering deluxe
- [] Rename subnets
- [X] Update route validation for ipv4
- [] Update route validation for ipv6
- [] Update Super Router diagram with vpcs configured for centralized
  egress.
- [] Update centralized egress docs for readme
- [] Update readme prereqs

Demo:
- Pre-requisite:
  - AWS account, may need to increase your VPC and or TGW quota for each us-east-1 and us-west-2 depending on how many you currently have.
  - IPAM CIDR pools in us-west-2 and us-east-1
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

Routing and peering Validation with AWS Route Analyzer:
- Go to [AWS Network Manager](https://us-west-2.console.aws.amazon.com/networkmanager/home?region=us-east-1#/networks) (free to use)
  - Create global network (or select existing global network)-> `next`
    - UNCHECK `Add core network in your global network` or you will be billed extra -> `next`
  - Select new global network -> go to `Transit Gateways` -> `Register
    Transit Gateway` -> Select TGWs -> `Register Transit Gateway` -> wait until all states say `Available`
  - Go to `Transit gateway network` -> `Route Analyzer`
    - IPv4:
        - Intra-Region Test 1 (general1 usw2c to thunderbird usw2a)
          - Source:
            - Transit Gateway: Choose `TEST-centralized-router-thunderbird-usw2`
            - Transit Gateway Attachment: Choose `TEST-tiered-vpc-random2-usw2 <-> TEST-centralized-router-thunderbird-usw2` (VPC)
            - IP Address: `192.168.2.7` (`random2` private subnet)
          - Destination:
            - Transit Gateway: Choose `TEST-centralized-router-storm-usw2`
            - Transit Gateway Attachment: Choose `TEST-tiered-vpc-cicd1-usw2 <-> TEST-centralized-router-storm-usw2` (VPC)
            - IP Address: `172.16.5.9` (`various1` public subnet)
          - Select `Run Route Analysis`
            - Forward and Return Paths should both have a `Connected` status.
        - Intra-Region Test 2 (infra2 use1c to app2 use1c)
          - Source:
            - Transit Gateway: Choose `TEST-centralized-router-bishop-use1`
            - Transit Gateway Attachment: Choose `TEST-tiered-vpc-infra2-use1 <-> TEST-centralized-router-bishop-use1` (VPC)
            - IP Address: `192.168.67.8` (`jenkins3` private subnet)
          - Destination:
            - Transit Gateway: Choose `TEST-centralized-router-wolverine-use1`
            - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app2-use1 <-> TEST-centralized-router-wolverine-use1` (VPC)
            - IP Address: `10.0.67.4` (`natgw3` public subnet)
          - Select `Run Route Analysis`
            - Forward and Return Paths should both have a `Connected` status.
        - Cross-Region Test 1 (app1 usw2a to general2 use1c)
          - Source:
            - Transit Gateway: Choose `TEST-centralized-router-thunderbird-usw2`
            - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app1-usw2 <-> TEST-centralized-router-thunderbird-usw2` (VPC)
            - IP Address: `10.0.21.65` (`haproxy1` public subnet)
          - Destination:
            - Transit Gateway: Choose `TEST-centralized-router-wolverine-use1`
            - Transit Gateway Attachment: Choose `TEST-tiered-vpc-general2-use1 <-> TEST-centralized-router-wolverine-use1` (VPC)
            - IP Address: `192.168.137.6` (`experiment14` private subnet)
          - Select `Run Route Analysis`
            - Forward and Return Paths should both have a `Connected` status.
        - Cross-Region Test 2 (cicd2 use1a to infra1 usw2c)
          - Source:
            - Transit Gateway: Choose `TEST-centralized-router-bishop-use1`
            - Transit Gateway Attachment: Choose `TEST-tiered-vpc-cicd2-use1 <-> TEST-centralized-router-bishop-use1` (VPC)
            - IP Address: `10.1.65.3` (`jenkins1` private subnet)
          - Destination:
            - Transit Gateway: Choose `TEST-centralized-router-storm-usw2`
            - Transit Gateway Attachment: Choose `TEST-tiered-vpc-infra1-usw2 <-> TEST-centralized-router-storm-usw2` (VPC)
            - IP Address: `10.2.5.6` (`jenkins3` private subnet)
          - Select `Run Route Analysis`
            - Forward and Return Paths should both have a `Connected` status.

Several other routes can be validated, try them out!

Tear down:
 - `terraform destroy` (long delay to get to yes or no prompt, be patient)

