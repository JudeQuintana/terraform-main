# Super Router Revamped
Build a decentralized hub and spoke topology both intra-region and cross-region.

Super Router now fully interprets AWS TGW network intent across address space, topology, and egress semantics, with no special cases.

What's new:
- Full support for IPv4 and IPv6, including primary and secondary CIDRs
- Ability to define blackhole CIDRs on either side of Super Router
- Operates on semantic facts (CIDRs × route table identities) rather than emitted route artifacts
- Compatible with Centralized Router v1.0.6

Semantic Coverage:
Super Router now provides complete semantic coverage of the AWS TGW routing domain:
- Expressive: handles all CIDR and address-family combinations
- Compositional: hierarchical domains compose cleanly
- Complete: covers the full AWS TGW routing semantic space

Important Info:
- Dual stack VPCs, Centralized Routers (Regional IR) with IPAM and Super Router (Domain IR)
- This is the dual stack version of the IPv4 only [Super Router demo](https://github.com/JudeQuintana/terraform-main/tree/main/super_router_demo).
- Both IPv4 and IPv6 secondary CIDRs are supported.
- Start with IPv4 only and add IPv6 at a later time or start with both.
- Demo does not work as-is because these Amazon owned IPv6 CIDRs have been allocated to my AWS account.
  - The IPv6 address will be different for your account.
  - You'll need to configure your own IPv4 and IPv6 cidr pools/subpools and there is IPAM instructions below.
- Terraform state is local in this demo.
  - Users should decide what they need for remote state.

Pre-requisites:
  - In your AWS account, you may need to increase your VPC, TGW, (etc) service quotas for each `us-east-1` and `us-west-2` depending on how many you currently have.
  - This demo will be creating 4 more VPCs in each region (8 total) and 3 TGWs in each region (6 total)
  - Each Centralized Router is configured with centralzed egress for the attached VPCs.
    - That means there will be 4 VPCs per region 3 NATGWs/EIPs (per enabled AZ) for each Centralized Router's region (6 EIPs total).
    - Increase the following quotas in each region for `us-east-1` and `us-west-2`:
Need at least 4 or more VPCs (default is 5 but it should suffice is starting with 0 VPCs):
```
For AWS Services, select Amazon Virtual Private Cloud (Amazon VPC).
Choose VPCs per Region.
Choose Request increase at account-level.
```

Need at least 4 or more Internet gateways (default is 5 but it should suffice is starting with 0 IGWs):
```
For AWS Services, select Amazon Virtual Private Cloud (Amazon VPC).
Choose Internet gateways per Region.
Choose Request increase at account-level.
```

Need at least 4 or more Egress-only Internet gateways for IPv6 egress (default is 5 but it should suffice is starting with 0 IEGWs):
```
For AWS Services, select Amazon Virtual Private Cloud (Amazon VPC).
Choose Egress-only internet gateways per Region.
Choose Request increase at account-level.
```

Need at least 6 or more EIPs (default is 5):
```
For AWS Services, select Amazon Elastic Compute Cloud (Amazon EC2).
Choose EC2-VPC Elastic IPs.
Choose Request increase at account-level.
```

Need at least 3 TGWs per account (default is 5 but it should suffice is starting with 0 TGWs):
```
For AWS Services, select Amazon Elastic Compute Cloud (Amazon EC2).
Choose Transit gateways per account.
Choose Request increase at account-level.
```
  - Centralized Routers and VPCs dont have to be in a centralized egress configuration but helps with scaling VPCs at cost (can also safely step down to non centralized egress config).
  - Need Pre-existing IPAM CIDR pools for IPv4 and IPv6 in `us-west-2`and `us-east-1`.
- [Super Router](https://github.com/JudeQuintana/terraform-aws-super-router/tree/v1.0.1) module provides both intra-region and cross-region peering and routing for Centralized Routers and Tiered VPCs (same AWS account only, no cross account).

The resulting architecture is a decentralized hub spoke topology:
- not shown but each IPv6 egress will go out its region's eigw if enabled.
![super-router-revamped](https://jq1-io.s3.amazonaws.com/super-router/super-router-revamped.png)

---

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

There can be many VPCs with `private = true` per Centralized Router Regional IR.

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

However, if there is no relative AZ with a NATGW in the egress VPC, the private subnet
traffic will route out of a cross AZ NATGW (if any) in the egress VPC.

Or traffic is load balance between more than one cross AZ NATGW if there are many AZs but no relative AZ NATGW.

Relative AZ example:
```
egress vpc (`central = true`)
- AZ `a` NATGW
- AZ `c` NATGW

vpc A (`private = true`)
- private subnets AZ `a` -> traffic routes out of egress VPC AZ `a` NATGW
- private subnets AZ `c` -> traffic routes out of egress VPC AZ `c` NATGW
```

Non-relative AZ example (not as cost effective due to cross AZ traffic):
```
egress vpc (`central = true`)
- AZ `a` NATGW
- AZ `b` NATGW

vpc B (opted into centralized egress with `private = true`)
- private subnets AZ `a` -> traffic routes out of egress VPC AZ `a` NATGW
- private subnets AZ `b` -> traffic routes out of egress VPC AZ `b` NATGW
- private subnets AZ `c` -> traffic route is "load balanced" between egress VPC AZ `a` and `b` NATGWs
```

Important notes:
- VPC subnet attribute `special` is synonymous with VPC attachment for the Centralized Router TGW.
- Each VPC configured with centralized egress `central = true` or `private = true`, the private and
  public subnets (if configured with `special = true`) will have access to VPC in the Centralized Router (Regional IR).
- Other VPCs can be added with out having to be configured for centralized egress but it makes sense that it probably should and can easily opt-in.
- It does not matter which subnet, private or public, has `special = true` set per AZ for VPC with `private = true` but it does matter for `central = true`.
- Isolated subnets only have access to subnets within the VPC (across AZs) but no access to other VPC AZs in the mesh.

### Decentralized IPv6 Egress
If a VPC's AZ is configured with private subnet IPv6 cidrs then you can
also add `eigw = true` per AZ to opt-into IPv6 traffic routing out of the
VPC's EIGW.

### Controlled Demolition
Important to remember:
- Always apply VPC configuration first, then Centralized Router, Super Router, and VPC Peering deluxe modules to keep state consistent.
- It is no longer required for a VPC's AZ to have a private or public subnet with `special = true` but
  if there are subnets with `special = true` then it must be either 1 private or 1 public subnet that has it
  configured per AZ (validation enforced for Tiered VPC-NG `v1.0.5+`).
- Any VPC that has a private or public subnet with `special = true`, that subnet will be used as
  the VPC attachment for it's AZ when passed to Centralized Router.
- If the VPC does not have any AZs with private or public subnet with `special = true` the AZs will be removed
  from the Centralized Router (Regional IR) and subsequently Super Router (Domain IR) and vpc peering (vpc peering deluxe) when applied.

AZ and VPC removal:
- There are times where an AZ or a VPC will need to be decomissioned.
- If an AZ is removed in the code that has a subnet with `special = true` then the subnet deletion will timeout.
- In order to safely remove the AZ:
  - `special = true` must be removed from the subnet and terraform apply the VPC(s) first
    - Then apply Centralized Router to remove the sunbet from the VPC attachment.
    - This will isolate the AZ from Centralized Router even though the AZ has route tables still pointing to other VPCs.
  - Remove AZ from the VPC and terraform apply VPCs again
    - removing an AZ can also be an example egress VPC AZ fail over depending on configuration.
  - Can be done for any VPC except if the VPC has the centralized egress `central = true` configuration.
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
  - Remove `special = true` from all subnets that have it set per AZ and apply VPCs first.
  - Apply Centralized Router and Super Router modules to remove the VPC routes from the Regional IR and Domain IR.
    - When there are no vpc attachements (`special = true`) on a VPC when passed to Centralized Router,
      the VPC and TGW routes will be removed from the Regional IR.
  - Remove VPC from code and apply VPCs to delete.
  - Apply VPC peering deluxe to update any subnet routing for the peering.

---

### VPC CIDRs Mappings
- `us-west-2`
  - app1 VPC Tier (`central = true`):
    - IPv4: `10.0.0.0/18`
    - IPv4 Secondaries: `10.1.0.0/20`
    - IPv6: `2600:1f24:66:c000::/56`
    - IPv6 Secondaries: `2600:1f24:66:cd00::/56`
  - general1 VPC Tier (`private = true`):
    - IPv4: `192.168.0.0/18`
    - IPv4 Secondaries: None
    - IPv6: `2600:1f24:66:c100::/56`
    - IPv6 Secondaries: None
  - cicd1 VPC Tier (`central = true`):
    - IPv4: `172.16.0.0/18`
    - IPv4 Secondaries: None
    - IPv6: `2600:1f24:66:c200::/56`
    - IPv6 Secondaries: None
  - infra1 VPC Tier (`private = true`):
    - IPv4: `10.2.0.0/18`
    - IPv4 Secondaries: None
    - IPv6: `2600:1f24:66:c600::/56`
    - IPv6 Secondaries: None
- `us-east-1`
  - app2 VPC Tier (`central = true`):
    - IPv4: `10.0.64.0/20`
    - IPv4 Secondaries: None
    - IPv6: `2600:1f28:3d:c000::/56`
    - IPv6 Secondaries: None
  - general2 VPC Tier (`private = true`):
    - IPv4: `192.168.128.0/20`
    - IPv4 Secondaries: None
    - IPv6: `2600:1f28:3d:c400::/56`
    - IPv6 Secondaries: None
  - cicd2 VPC Tier (`central = true`):
    - IPv4: `10.1.64.0/20`
    - IPv4 Secondaries: None
    - IPv6: `2600:1f28:3d:c700::/56`
    - IPv6 Secondaries: None
  - infra2 VPC Tier (`private = true`):
    - IPv4: `192.168.64.0/20`
    - IPv4 Secondaries: None
    - IPv6: `2600:1f28:3d:c800::/56`
    - IPv6 Secondaries: None

### IPAM Configuration
- There are many ways to configure IPAM so I manually created IPAM pools (advanced tier) in the AWS UI.
- Demo does not work as-is because these Amazon owned IPv6 CIDRs have been allocated to my AWS account.
- You'll need to configure your own IPv4 and IPv6 cidr pools/subpools.
- Advanced Tier IPAM in `us-west-2`, and `us-east-1` operating reigons.
  - In this demo, ipam pools for all locales are managed in the `us-west-2` region via AWS Console UI.
  - No IPv4 regional pools at the moment.
  - IPv6 subpools need a IPv6 regional pool with `/52` to be able to provision `/56` per locale.

  - `us-west-2` (ipam locale)
    - IPv4 Pool (private scope)
      - Description: `ipv4-test-usw2`
      - Provisioned CIDRs:
        - `10.0.0.0/18`
        - `10.1.0.0/20`
        - `192.168.0.0/18`
        - `172.16.0.0/18`
        - `10.2.0.0/18 `
    - IPv6 regional pool (public scope)
      - `2600:1f24:66:c000::/52`
        - IPv6 subpool (public scope)
          - Description: `ipv6-test-usw2`
          - Provisioned CIDRs:
            - `2600:1f24:66:c000::/56`
            - `2600:1f24:66:c100::/56`
            - `2600:1f24:66:c200::/56`
            - `2600:1f24:66:c600::/56`
            - `2600:1f24:66:cd00::/56`

  - `us-east-1` (ipam locale)
    - IPv4 Pool (private scope)
      - Description: `ipv4-test-use1`
      - Provisioned CIDRs:
        - `10.0.64.0/20`
        - `10.1.64.0/20`
        - `192.168.64.0/20`
        - `192.168.128.0/20`
    - IPv6 regional pool (public scope)
      - `2600:1f28:3d:c000::/52`
        - IPv6 subpool (public scope)
          - Description: `ipv6-test-use1`
          - Provisioned CIDRs:
            - `2600:1f28:3d:c000::/56`
            - `2600:1f28:3d:c400::/56`
            - `2600:1f28:3d:c700::/56`
            - `2600:1f28:3d:c800::/56`

---

## Begin Demo
It begins:
 - `terraform init`

Apply Tiered-VPCs (must exist before Centralized Routers) and S3 Gateways:
 - `terraform apply -target module.vpcs_usw2 -target module.vpcs_another_usw2 -target module.vpcs_use1 -target module.vpcs_another_use1`

Apply Centralized Routers (must exist before Super Router), Intra VPC Security Group Rules and S3 Gateways (if enabled in variables.tf):
 - `terraform apply -target module.centralized_routers_usw2 -target module.centralized_routers_use1 -target module.intra_vpc_security_group_rules_usw2 -target module.intra_vpc_security_group_rules_use1 -target aws_vpc_endpoint.s3_use1 -target aws_vpc_endpoint.s3_usw2`

Apply Super Router and Super Intra VPC Security Group Rules:
 - `terraform apply -target module.super_router_usw2_to_use1 -target module.super_intra_vpc_security_group_rules_usw2_to_use1`

The Super Router is now complete!

---

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
        - IP Address: `10.2.5.6` (`thing5` private subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
  - IPv6:
    - Intra-Region Test 1 (general1 usw2c to thunderbird usw2a)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-thunderbird-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-random2-usw2 <-> TEST-centralized-router-thunderbird-usw2` (VPC)
        - IP Address: `2600:1f24:66:c102:0000:0000:0000:0001` (`random2` private subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-storm-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-cicd1-usw2 <-> TEST-centralized-router-storm-usw2` (VPC)
        - IP Address: `2600:1f24:66:c202:0000:0000:0000:0002` (`various1` public subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Intra-Region Test 2 (infra2 use1c to app2 use1c)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-bishop-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-infra2-use1 <-> TEST-centralized-router-bishop-use1` (VPC)
        - IP Address: `2600:1f28:3d:c802:0000:0000:0000:0003` (`jenkins3` private subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-wolverine-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app2-use1 <-> TEST-centralized-router-wolverine-use1` (VPC)
        - IP Address: `2600:1f28:3d:c00a:0000:0000:0000:0004` (`natgw3` public subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Cross-Region Test 1 (app1 usw2a to general2 use1c)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-thunderbird-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-app1-usw2 <-> TEST-centralized-router-thunderbird-usw2` (VPC)
        - IP Address: `2600:1f24:66:c001:0000:0000:0000:0002` (`haproxy1` public subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-wolverine-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-general2-use1 <-> TEST-centralized-router-wolverine-use1` (VPC)
        - IP Address: `2600:1f28:3d:c40a:0000:0000:0000:0003` (`experiment14` private subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.
    - Cross-Region Test 2 (cicd2 use1a to infra1 usw2c)
      - Source:
        - Transit Gateway: Choose `TEST-centralized-router-bishop-use1`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-cicd2-use1 <-> TEST-centralized-router-bishop-use1` (VPC)
        - IP Address: `2600:1f28:3d:c700:0000:0000:0000:0004` (`jenkins1` private subnet)
      - Destination:
        - Transit Gateway: Choose `TEST-centralized-router-storm-usw2`
        - Transit Gateway Attachment: Choose `TEST-tiered-vpc-infra1-usw2 <-> TEST-centralized-router-storm-usw2` (VPC)
        - IP Address: `2600:1f24:66:c604:0000:0000:0000:0005` (`thing5` private subnet)
      - Select `Run Route Analysis`
        - Forward and Return Paths should both have a `Connected` status.

Several other routes can be validated, try them out!

Tear down:
 - `terraform destroy` (long delay)

