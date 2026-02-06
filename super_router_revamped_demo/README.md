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
- [x] Update IPv6 blackhole cidrs
- [x] Add intra and cross region vpc peering deluxe
- [x] Rename subnets
- [x] Update route validation for ipv4
- [x] Update route validation for ipv6
- [x] Add s3 gateway toggle
- [x] Update Super Router diagram with vpcs configured for centralized
  egress.
- [x] publish and update modules on TF registry
- [] Update readme prereqs
- [] Update centralized egress docs for readme

Pre-requisites:
  - In your AWS account, you may need to increase your VPC and/or TGW quota for each us-east-1 and us-west-2 depending on how many you currently have.
  - This demo will be creating 4 more VPCs in each region (8 total) and 3 TGWs in each region (6 total)
  - Each Centralized Router is configured with centralzed egress for the attached VPCs.
    - That means there will be 4 VPCs per region 3 NATGWs/EIPs (per enabled AZ) for each Centralized Router's region (6 EIPs total).
    - Increase the following quotas in each region for `us-east-1` and `us-west-2`:
      - Need at least 4 or more VPCs (default is 5 but it should suffice is starting with 0 VPCs):
```
For AWS Services, select Amazon Virtual Private Cloud (Amazon VPC).
Choose VPCs per Region.
Choose Request increase at account-level.
```
      - Need at least 4 or more Internet gateways (default is 5 but it should suffice is starting with 0 IGWs)::
```
For AWS Services, select Amazon Virtual Private Cloud (Amazon VPC).
Choose Internet gateways per Region.
Choose Request increase at account-level.
```
      - Need at least 4 or more Egress-only Internet gateways (default is 5 but it should suffice is starting with 0 IEGWs):
```
For AWS Services, select Amazon Virtual Private Cloud (Amazon VPC).
Choose Egress-only internet gateways per Region.
Choose Request increase at account-level.
```
      - Need at least 6 or more EIPs (default is 5):
```
For AWS Services, select Amazon Elastic Compute Cloud (Amazon EC2).
Choose EC2-VPC Elastic IPs.
Choose Request increase at account-level.
```
      - Need at least 3 TGWs per account (default is 5 but it should suffice is starting with 0 TGWs):
```
For AWS Services, select Amazon Elastic Compute Cloud (Amazon EC2).
Choose Transit gateways per account.
Choose Request increase at account-level.
```
    - Centralized Routers and VPCs dont have to be in a centralized
      egress configuration but helps with scaling VPCs at cost (can also safely step down to non centralized egress config).
  - Pre-existing IPAM CIDR pools for IPv4 and IPv6 in us-west-2 and us-east-1
- [Super Router](https://github.com/JudeQuintana/terraform-modules/tree/master/networking/tgw_super_router_for_tgw_centralized_router) module provides both intra-region and cross-region peering and routing for Centralized Routers and Tiered VPCs (same AWS account only, no cross account).

The resulting architecture is a decentralized hub spoke topology:
![super-router-shokunin](https://jq1-io.s3.amazonaws.com/super-router/super-router-revamped.png)

### VPC CIDRs
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

## Begin Demo
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
 - `terraform destroy` (long delay to get to yes or no prompt, be patient)

