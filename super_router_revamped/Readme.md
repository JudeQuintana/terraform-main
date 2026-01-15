# Super Router Revamped WIP
Build a decentralized hub and spoke topology both intra-region and cross-region.

Refactor is a work in progress:
- Requires IPAM (done)
- Super router refactor for IPv4 network cidrs (works!)
- Building support for IPv4 secondaries (wip)
  - Currently IPv4 secondaries are not working!

Errors
│ Error: creating Route in Route Table (rtb-0a6bedcff80216023) with destination (10.1.0.0/20): operation error EC2: CreateRoute, https response error StatusCode: 400, RequestID: 7c79e8ad-b176-4405-885d-ef8e35b709fd, api error InvalidParameterValue: The destination CIDR block 10.1.0.0/20 is equal to or more specific than one of this VPC's CIDR blocks. This route can target only an interface or an instance.
│
│   with module.super_router_usw2_to_use1.aws_route.this_local_vpcs_routes_to_local_vpcs["rtb-0a6bedcff80216023|10.1.0.0/20"],
│   on .terraform/modules/super_router_usw2_to_use1/networking/tgw_super_router_for_tgw_centralized_router/local_routes.tf line 139, in resource "aws_route" "this_local_vpcs_routes_to_local_vpcs":
│  139: resource "aws_route" "this_local_vpcs_routes_to_local_vpcs" {
│
╵
╷
│ Error: creating Route in Route Table (rtb-05cea81d91f3b24c7) with destination (10.1.0.0/20): operation error EC2: CreateRoute, https response error StatusCode: 400, RequestID: ec7b6725-b5b2-453b-94f9-e5a76e9c4324, api error InvalidParameterValue: The destination CIDR block 10.1.0.0/20 is equal to or more specific than one of this VPC's CIDR blocks. This route can target only an interface or an instance.
│
│   with module.super_router_usw2_to_use1.aws_route.this_local_vpcs_routes_to_local_vpcs["rtb-05cea81d91f3b24c7|10.1.0.0/20"],
│   on .terraform/modules/super_router_usw2_to_use1/networking/tgw_super_router_for_tgw_centralized_router/local_routes.tf line 139, in resource "aws_route" "this_local_vpcs_routes_to_local_vpcs":
│  139: resource "aws_route" "this_local_vpcs_routes_to_local_vpcs" {
│
╵
╷
│ Error: api error RouteAlreadyExists: Route in Route Table (rtb-08db6e490a89f45d9) with destination (10.1.0.0/20) already exists
│
│   with module.super_router_usw2_to_use1.aws_route.this_local_vpcs_routes_to_local_vpcs["rtb-08db6e490a89f45d9|10.1.0.0/20"],
│   on .terraform/modules/super_router_usw2_to_use1/networking/tgw_super_router_for_tgw_centralized_router/local_routes.tf line 139, in resource "aws_route" "this_local_vpcs_routes_to_local_vpcs":
│  139: resource "aws_route" "this_local_vpcs_routes_to_local_vpcs" {
│
╵
╷
│ Error: creating EC2 Transit Gateway Route (tgw-rtb-0b4abfc99b5e16839_10.1.0.0/20): operation error EC2: CreateTransitGatewayRoute, https response error StatusCode: 400, RequestID: 154e9be2-918d-411f-8f17-27ba7318e1f3, api error RouteAlreadyExists: Route 10.1.0.0/20 already exists in Transit Gateway Route Table tgw-rtb-0b4abfc99b5e16839.
│
│   with module.super_router_usw2_to_use1.aws_ec2_transit_gateway_route.this_local_tgw_routes_to_local_tgws["tgw-rtb-0b4abfc99b5e16839|10.1.0.0/20"],
│   on .terraform/modules/super_router_usw2_to_use1/networking/tgw_super_router_for_tgw_centralized_router/local_routes.tf line 198, in resource "aws_ec2_transit_gateway_route" "this_local_tgw_routes_to_local_tgws":
│  198: resource "aws_ec2_transit_gateway_route" "this_local_tgw_routes_to_local_tgws" {

TODO:
- Finish support for IPv4 secondaries.
- Support IPv6 and secondaries for super router revamped.
- Build IPv6 version of super intra vpc security group rules.
- Enable centralized egress per centralized router.
- Add intra and cross region vpc peering deluxe.


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

