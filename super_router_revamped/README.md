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
- [] Update route validation for ipv4 and ipv6
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
- Will update later

Tear down:
 - `terraform destroy` (long delay to get to yes or no prompt, be patient)

