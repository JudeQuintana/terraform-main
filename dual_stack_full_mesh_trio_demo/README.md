# Dual Stack Full Mesh Trio Demo
- Dual stack Full Mesh Transit Gateway across 3 regions
- This is the dual stack version of the (IPv4 only) [Full Mesh Trio demo](https://github.com/JudeQuintana/terraform-main/tree/main/full_mesh_trio_demo).
- Demo does not work as-is because these Amazon owned IPv6 CIDRs have been allocated to my AWS account. You'll need to configure your own IPv4 and IPv6 cidr pools/subpools.
- Both IPv4 and IPv6 secondary cidrs are supported.
- Start with IPv4 only and add IPv6 at a later time or start with both.

VPC CIDRs:
- `us-east-2`
  - App1 VPC Tier:
    - IPv4: `172.16.64.0/18`
    - IPv4 Secondaries: `172.16.192.0/20`
    - IPv6: `2600:1f26:21:c000::/56`
    - IPv6 Secondaries: `2600:1f26:21:c400::/56`
  - General1 VPC Tier:
    - IPv4: `172.16.128.0/18`
    - IPv4 Secondaries: `172.16.208.0/20`
    - IPv6: `2600:1f26:21:c100::/56`
    - No IPv6 Secondaries

- `us-west-2`
  - App2 VPC Tier:
    - IPv4: `10.0.0.0/18`
    - IPv4 Secondaries: `10.1.0.0/20`
    - IPv6: `2600:1f24:66:c000::/56`
    - No IPv6 Secondaries
  - General2 VPC Tier:
    - IPv4: `192.168.0.0/18`
    - IPv4 Secondaries: `192.168.144.0/20`
    - IPv6: `2600:1f24:66:c100::/56`
    - No IPv6 Secondaries

- `us-east-1`
  - App3 VPC Tier:
    - IPv4: `10.0.64.0/18`
    - IPv4 Secondaries: `10.1.64.0/20`
    - IPv6: `2600:1f28:3d:c000::/56`
    - No IPv6 Secondaries
  - General3 VPC Tier:
    - IPv4: `192.168.64.0/18`
    - IPv4 Secondaries: `192.168.128.0/20`
    - IPv6: `2600:1f28:3d:c400::/56`
    - No IPv6 Secondaries

VPCs with an IPv4 network cidr /18 provides /20 subnet for each AZ (up to 4 AZs).

The resulting architecture is a ipv4 only or a dual stack full mesh topology across 3 regions:
![dual-stack-full-mesh-trio](https://jq1-io.s3.us-east-1.amazonaws.com/dual-stack/dual-stack-full-mesh-trio.png)

IPAM Configuration
- There are many ways to configure IPAM so I manually created IPAM pools (advanced tier) in the AWS UI.
- You need to make your own IPv6 IPAM pools since my AWS Account has allocations from these specific AWS owned IPv6 CIDRs so the demo will not work as is with other AWS accounts.

- Advanced Tier IPAM in `us-east-2`, `us-west-2`, `us-east-1` and operating reigons.
  - In this demo, ipam pools for all locales are managed in the `us-west-2` region via AWS Console UI.
  - No IPv4 regional pools at the moment.
  - IPv6 subpools need a IPv6 regional pool with `/52` to be able to provision `/56` per locale.
  - `us-east-2` (ipam locale)
    - IPv4 Pool (private scope)
      - Provisioned CIDRs:
        - `172.16.64.0/18`
        - `172.16.128.0/18`
        - `172.16.192.0/20`
        - `172.16.208.0/20`
    - IPv6 regional pool (public scope)
      - `2600:1f26:21:c000::/52`
        - IPv6 subpool (public scope)
          - Provisioned CIDRs:
            - `2600:1f26:21:c000::/56`
            - `2600:1f26:21:c100::/56`
            - `2600:1f26:21:c400::/56`

  - `us-west-2` (ipam locale)
    - IPv4 Pool (private scope)
      - Provisioned CIDRs:
        - `10.0.0.0/18`
        - `10.1.0.0/20`
        - `192.168.0.0/18`
        - `192.168.144.0/20`
    - IPv6 regional pool (public scope)
      - `2600:1f24:66:c000::/52`
        - IPv6 subpool (public scope)
          - Provisioned CIDRs:
            - `2600:1f24:66:c000::/56`
            - `2600:1f24:66:c100::/56`

  - `us-east-1` (ipam locale)
    - IPv4 Pool (private scope)
      - Provisioned CIDRs:
        - `10.0.64.0/18`
        - `10.1.64.0/20`
        - `192.168.64.0/18`
        - `192.168.128.0/20`
    - IPv6 regional pool (public scope)
      - `2600:1f28:3d:c000::/52`
        - IPv6 subpool (public scope)
          - Provisioned CIDRs:
            - `2600:1f28:3d:c000::/56`
            - `2600:1f28:3d:c400::/56`

Build Dual Stack Full Mesh Trio
1. It begins:
  - `terraform init`

2. Apply Tiered-VPCs (must exist before Centralized Routers, VPC Peering Deluxe and Full Mesh Intra VPC Security Group Rules):
  - `terraform apply -target module.vpcs_use1 -target module.vpcs_use2 -target module.vpcs_usw2`

3. Apply Full Mesh Intra VPC Security Group Rules and IPv6 Full Mesh Intra VPC Security Group Rules (will auto apply it's dependent modules Intra Security Group Rules and IPv6 Intra Security Group Rules for each region) for EC2 access across VPC regions (ie ssh and ping) for VPCs in a TGW Full Mesh configuration.
  - `terraform apply -target module.full_mesh_intra_vpc_security_group_rules -target module.ipv6_full_mesh_intra_vpc_security_group_rules`

4. Apply VPC Peering Deluxe and Centralized Routers:
  - `terraform apply -target module.vpc_peering_deluxe_usw2_app2_to_usw2_general2 -target module.vpc_peering_deluxe_use1_general3_to_use2_app1 -target module.centralized_router_use1 -target module.centralized_router_use2 -target module.centralized_router_usw2`

5. Apply Full Mesh Trio:
  - `terraform apply -target module.full_mesh_trio`

Note: combine steps 3 through 5 with: `terraform apply`

Routing and peering validation with AWS Route Analyzer:
- Go to [AWS Network Manager](https://us-west-2.console.aws.amazon.com/networkmanager/home?region=us-east-1#/networks) (free to use)
  - Create global network -> `next`
    - UNCHECK `Add core network in your global network` or you will be billed extra -> `next`
  - Select new global network -> go to `Transit Gateways` -> `Register
    Transit Gateway` -> Select TGWs -> `Register Transit Gateway` -> wait until all states say `Available`
  - Go to `Transit gateway network` -> `Route Analyzer`

  - IPv4:
    - Cross-Region Test 1 (use1a to use2c)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-mystique-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-general3-use1 <-> TEST-centralized-router-mystique-use1` (VPC)
        - IP Address: `192.168.68.70` (`haproxy1` public subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-magento-use2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-general1-use2 <-> TEST-centralized-router-magneto-use2` (VPC)
        - IP Address: `172.16.132.6` (`jenkins2` private subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Cross-Region Test 2 (use2b to usw2c)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-magneto-use2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app1-use2 <-> TEST-centralized-router-magneto-use2` (VPC)
        - IP Address: `172.16.76.21` (`other2` public subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-arch-angel-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-general2-usw2 <-> TEST-centralized-router-arch-angel-usw2` (VPC)
        - IP Address: `192.168.11.11` (`db2` private subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Cross-Region Test 3 (usw2b to use1b)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-arch-angel-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app2-usw2 <-> TEST-centralized-router-arch-angel-usw2` (VPC)
        - IP Address: `10.0.16.16` (`cluster2` private subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-mystique-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app3-use1 <-> TEST-centralized-router-mystique-use1` (VPC)
        - IP Address: `10.1.64.4` (`other1` public subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.

  - IPv6:
    - Cross-Region Test 1 (use1a to use2c)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-mystique-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-general3-use1 <-> TEST-centralized-router-mystique-use1` (VPC)
        - IP Address: `2600:1f28:3d:c402:0000:0000:0000:0002` (`haproxy1` public subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-magento-use2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-general1-use2 <-> TEST-centralized-router-magneto-use2` (VPC)
        - IP Address: `2600:1f26:21:c103:0000:0000:0000:0003` (`jenkins2` private subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Cross-Region Test 2 (use2b to usw2c)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-magneto-use2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app1-use2 <-> TEST-centralized-router-magneto-use2` (VPC)
        - IP Address:
          `2600:1f26:21:c003:0000:0000:0000:0004` (`other2` public subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-arch-angel-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-general2-usw2 <-> TEST-centralized-router-arch-angel-usw2` (VPC)
        - IP Address: `2600:1f24:66:c101:0000:0000:0000:0005` (`db2` private subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Cross-Region Test 3 (usw2b to use1b)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-arch-angel-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app2-usw2 <-> TEST-centralized-router-arch-angel-usw2` (VPC)
        - IP Address: `2600:1f24:66:c006:0000:0000:0000:0006` (`cluster2` private subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-mystique-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app3-use1 <-> TEST-centralized-router-mystique-use1` (VPC)
        - IP Address: `2600:1f28:3d:c006:0000:0000:0000:0007` (`other1` public subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.

Several other routes can be validated, try them out!

Tear down:
 - `terraform destroy`
   - Full teardown (destroy) works for AWS provider 5.61.0 but the VPC destroy in the last step will take about 10-30 min to finish deleting cleanly after waiting for AWS to release IPAM pool CIDRs without error. Now you can immediately rebuild with the same cidrs after the destroy.
