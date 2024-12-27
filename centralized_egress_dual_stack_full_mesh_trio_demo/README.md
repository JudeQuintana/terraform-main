# Dual Stack Full Mesh Trio with Centralized IPv4 Egress and Decentrized IPv6 Egress Demo
- Centralized IPv4 Egress and Decentralized IPv6 Egress within a Dual Stack Full Mesh Topology across 3 regions.
  - Taking a more cost effective approach to Dual Stack Full Mesh Trio Demo
- A demonstration of how scaling centralized ipv4 egress in code can be a subset behavior from minimal configuration of tiered vpc-ng and centralized router within a full mesh topology.
  - Both IPv4 and IPv6 secondary cidrs are supported.
  - No network firewall.
  - Start with IPv4 only and add IPv6 at a later time or start with both.
  - Tested with Terraform v1.5.7 so it should also work with OpenTofu.
- Demo does not work as-is because these Amazon owned IPv6 CIDRs have been allocated to my AWS account.
  - You'll need to configure your own IPv4 and IPv6 cidr pools/subpools.
- AWS general reference: [Centralized Egress](https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/using-nat-gateway-for-centralized-egress.html)
  - Setup is not exactly like the linked architecture since I'm not using multiple route tables, only one.

### Centralized IPv4 Egress
Egress VPC:

There can only be one VPC with a `central = true` centralized egress
confguration in a Centralized Router.
```
    {
      name = "general1"
      ipv4 = {
        ...
        centralized_egress = {
          central   = true
        }
      }
    ...
```

Validation will enforce:
- the VPC must have a NATGW per AZ
- the VPC must have a private subnet with `special = true` per AZ

Centralized router will add the `0.0.0.0/0` -> `egress-vpc-attachment-id` route
to it's transit gateway route table.

Now each VPC with `private = true`, all private subnet egress traffic
will route out of the relative AZ NATGW in egress VPC with `central = true`.

---
VPCs that opt-in to sending private AZ traffic out of the Egress VPC NATGWs:

There can be many VPCs with `private = true` per Centralized Router regional mesh.

Validation will enforce
- the VPC cannot have a NATGW per AZ.
```
    {
      name = "app1"
      ipv4 = {
        ...
        centralized_egress = {
          private = true
        }
      }
    ...
```

Centralized Router will add the `0.0.0.0/0` -> `tgw-id` route to the private subnet route tables per AZ.

However, if there is no relative AZ with NATGW in the egress VPC, the private subnet
traffic will route out of a cross AZ NATGW (if any) in the egress VPC.

Or traffic is load balance between more than one egress VPC AZ NATGW if there are many AZ but there is no relative AZ to the opt-in VPC.

Relative AZ example:
```
egress vpc
- AZ `a` NATGW
- AZ `c` NATGW

vpc A (opted into centralized egress with `private = true`)
- private subnets AZ `a` -> traffic routes out of egress VPC AZ `a`
- private subnets AZ `c` -> traffic routes out of egress VPC AZ `c`
```

Non-relative AZ example:
```
egress vpc
- AZ `a` NATGW
- AZ `b` NATGW

vpc B (opted into centralized egress with `private = true`)
- private subnets AZ `a` -> traffic routes out of egress VPC AZ `a`
- private subnets AZ `b` -> traffic routes out of egress VPC AZ `b`
- private subnets AZ `c` -> traffic route is "load balanced" between egress VPC AZ `a` and `b`
```

Imporant notes:
- Each VPC configured with centralized egress `central = true` or `private = true`, the private and
  public subnets (if configured with `special = true`) will have access to VPC in the Centralized Router regional mesh.
- If there are VPCs configured with centralized egress, other VPCs can be added with out having to be
  configured for centralized egress but it makes sense that it probably should and can easily opt-in.
- Isolated subnets within an AZ only has access to subnets with in the VPC across it's AZs but no access to or from other AZs in the mesh.

### Decentralized IPv6 Egress
If a VPC's AZ is configured with private subnet IPv6 cidrs then you can
also add `eigw = true` per AZ to opt-into IPv6 traffic routing out of the
VPC's EIGW.

### Controlled Demolition
Important to remember:
- Always apply VPC configuration first, then Centralized Router, Full Mesh Trio, and VPC Peering deluxe modules to keep state consistent.
- It is no longer required for a VPC's AZ to have a private or public subnet with `special = true` but
  if there are subnets with `special = true` then it must be either 1 private or 1 public subnet that has it
  configured per AZ (validation enforced).
- Any VPC that has a private or public subnet with `special = true`, that subnet will be used as
  the VPC attachment for it's AZ when passed to Centralized Router.
- If the VPC does not have any AZs with private or public subnet with `special = true` it will be removed
  from the Centralized Router regional mesh and subsequently the cross regional mesh (full mesh trio) and vpc peering (vpc peering deluxe).

AZ and VPC removal:
- There are times where an AZ or a VPC will need to be decomissioned.
- If an AZ is removed in the code that has a subnet with `special = true` then the subnet deletion will timeout.
- In order to safely remove the AZ:
  - `special = true` must be removed from the subnet and terraform apply the VPC(s) first.
    - this will isolate the AZ from regional mesh even though the AZ has
      route tables still pointing to other VPCs.
  - Remove AZ from the VPC and terraform apply VPCs again
  - Then apply Centralized Router and Full Mesh Trio to keep the
    regional and cross regional mesh updated.
  - Can be done for any VPC except if the VPC has the centralized egress
    `central = true` configuration.
    - The egress VPC validation will block removing an AZ
    - The validation can be bypassed with centralized egress `remove_az = true` then proceed with the AZ removal steps.
```
    {
      name = "general1"
      ipv4 = {
        ...
        centralized_egress = {
          central   = true
          remove_az = true
        }
      }
    ...
```

- Safely remove a VPC:
  - Remove `special = true` from each subnet that has it per AZ and appy VPCs first.
  - Apply Centralized Router and Full mesh Trio modules to remove the
    VPC routes from the regional and cross regional mesh.
    - When there are no vpc attachements (`special = true`) on a VPC when passed to Centralized Router,
      the VPC and TGW routes will be removed from the regional mesh.
  - Apply VPC peering deluxe to update any subnet routing for the peering.
  - remove VPC from code and apply VPCs to delete.

---
## Begin Demo

### VPC CIDRs
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

The resulting architecture is a centralized ipv4 egress and decentralized ipv6 egress in a dual stack full mesh topology across 3 regions:
![dual-stack-full-mesh-trio](https://jq1-io.s3.us-east-1.amazonaws.com/dual-stack/dual-stack-full-mesh-trio.png)

### IPAM Configuration
- There are many ways to configure IPAM so I manually created IPAM pools (advanced tier) in the AWS UI.
- Demo does not work as-is because these Amazon owned IPv6 CIDRs have been allocated to my AWS account.
- You'll need to configure your own IPv4 and IPv6 cidr pools/subpools.
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

### Build Dual Stack Full Mesh Trio
1. It begins: - `terraform init`

2. Apply Tiered-VPCs (must exist before Centralized Routers, VPC Peering Deluxe and Full Mesh Intra VPC Security Group Rules):
  - `terraform apply -target module.vpcs_use1 -target module.vpcs_use2 -target module.vpcs_usw2`

3. Apply Full Mesh Intra VPC Security Group Rules and IPv6 Full Mesh Intra VPC Security Group Rules (will auto apply it's dependent modules Intra Security Group Rules and IPv6 Intra Security Group Rules for each region) for EC2 access across VPC regions (ie ssh and ping) for VPCs in a TGW Full Mesh configuration.
  - `terraform apply -target module.full_mesh_intra_vpc_security_group_rules -target module.ipv6_full_mesh_intra_vpc_security_group_rules`

4. Apply VPC Peering Deluxe and Centralized Routers:
  - `terraform apply -target module.vpc_peering_deluxe_usw2_app2_to_usw2_general2 -target module.vpc_peering_deluxe_use1_general3_to_use2_app1 -target module.centralized_router_use1 -target module.centralized_router_use2 -target module.centralized_router_usw2`

5. Apply Full Mesh Trio:
  - `terraform apply -target module.full_mesh_trio`

Note: combine steps 3 through 5 with: `terraform apply`

### Routing and peering validation with AWS Route Analyzer
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
        - IP Address: `192.168.11.11` (`util1` private subnet)
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

### Tear down
 - `terraform destroy`
   - Full teardown (destroy) works for AWS provider 5.61.0 but the VPC destroy in the last step will take about 10-30 min to finish deleting cleanly after waiting for AWS to release IPAM pool CIDRs without error. Now you can immediately rebuild with the same cidrs after the destroy.