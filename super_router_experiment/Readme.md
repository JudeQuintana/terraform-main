Demo: Rough draft of super router.

A scalable way (hopefully) to route intra-region and cross-region (same aws acct for now) central router tgws and vpcs via super router tgw. no cross account support yet.

Validated connectivity with aws route analyzer.
(ec2 usw2a <-> vpc usw2 <-> centralized router usw2 <-> super router usw2 <-> centralized router use1 <-> vpc use1 <-> ec2 use1a)

it begins
`terraform init`

VPCs must be applied first
`terraform apply -target module.vpcs_usw2 -target module.vpcs_use1`

launch centralized routers, intra-vpcs security groups and instances
`terraform apply -target module.tgw_centralized_router_usw2 -target module.tgw_centralized_router_use1`

launch super router
`terraform apply  -target module.tgw_super_router_usw2`

Validation with AWS Route Analyzer
- Go to [AWS Network Manager](https://us-west-2.console.aws.amazon.com/networkmanager/home#/networks) (free to use)
  - Create global network -> `next`
    - UNCHECK `Add core network in your global network` or you will be billed extra -> next
  - Select new global network -> go to `Transit Gateways` -> `Register
    Transit Gateway` -> Select TGWs -> `Register Transit Gateway` -> wait until all states say `Available`
  - Go to `Transit gateway network` -> `Route Analyzer`
    - Source:
      - Transit Gateway: Choose Centralized Router in usw2
      - Transit Gateway Attachment: Choose app-usw2 (VPC)
      - IP Address: 10.0.19.5
    - Destination:
      - Transit Gateway: Choose Centralized Router in use1
      - Transit Gateway Attachment: Choose general-use1 (VPC)
      - IP Address: 192.168.10.3
    - Select `Run Route Analysis`
      - Forward and Return Paths should both have a `Connected` status.
