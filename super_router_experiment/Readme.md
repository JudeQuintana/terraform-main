This is a follow up to the [generating routes post](https://jq1.io/posts/generating_routes/)

Demo:
- Rough draft of super router.
- A scalable way (hopefully) to route intra-region and cross-region central router tgws and vpcs via super router.
- peering and routing between the super router and centralized_routers within the same region and cross region works now (within same aws account only for now).
- The caveat is the peer TGWs will have to go through the super-router local provider region to get to other peer TGWs. Architecture diagrams, lol:
  - usw2 vpc 1 <-> usw2 centralized router 1 <-> usw2 super router <-> use1 centralized router 1 <-> use1 vpc 2
  - usw2 vpc 1 <-> usw2 centralized router 1 <-> usw2 super router <-> usw2 centralized router 2 <-> usw2 vpc 2
  - use1 vpc 1 <-> use1 centralized router 1 <-> usw2 super router <-> use1 centralized router 2 <-> use1 vpc 2

it begins
`terraform init`

VPCs must be applied first
`terraform apply -target module.vpcs_usw2 -target module.vpcs_use1`

launch centralized routers
`terraform apply -target module.tgw_centralized_router_usw2 -target module.tgw_centralized_router_use1`

launch super router
`terraform apply  -target module.tgw_super_router_usw2`

Validation with AWS Route Analyzer
- Go to [AWS Network Manager](https://us-west-2.console.aws.amazon.com/networkmanager/home#/networks) (free to use)
  - Create global network -> next
    - UNCHECK `Add core network in your global network` or you will be billed extra -> `next`
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
