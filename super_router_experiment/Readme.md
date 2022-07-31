This is a follow up to the [generating routes post](https://jq1.io/posts/generating_routes/)

Demo:
- Rough draft of super router.
- A scalable way (hopefully) to peer and route intra-region and cross-region central router tgws and vpcs via super router.
- The caveat is the peer TGWs will have to go through the super-router local provider region to get to other peer TGWs in the same region. Architecture diagrams, lol:
  - usw2 vpc 1 <-> usw2 centralized router 1 <-> usw2 super router <-> use1 centralized router 1 <-> use1 vpc 2
  - usw2 vpc 1 <-> usw2 centralized router 1 <-> usw2 super router <-> usw2 centralized router 2 <-> usw2 vpc 2
  - use1 vpc 1 <-> use1 centralized router 1 <-> usw2 super router <-> use1 centralized router 2 <-> use1 vpc 2
- [PR](https://github.com/JudeQuintana/terraform-modules/pull/6) for modules and TODO

it begins
`terraform init`

VPCs MUST be applied first
`terraform apply -target module.vpcs_usw2 -target module.vpcs_use1`

apply centralized routers
`terraform apply -target module.tgw_centralized_router_usw2 -target module.tgw_centralized_router_use1`

apply super router
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
