## Networking Trifecta Demo
Blog Post:
[Terraform Networking Trifecta ](https://jq1.io/posts/tiered_vpc/)

# Goal
Using the latest Terraform (v1.0.4+) and AWS Provider (v3.53.0+)
route between 3 VPCs with different IPv4 CIDR ranges (RFC 1918)
using a Transit Gateway.

- App VPC Tier: `10.0.0.0/20` (Class A Private Internet)
- CICD VPC Tier: `192.168.0.0/20` (Class B Private Internet)
- General VPC Tier: `172.16.0.0/20` (Class C Private Internet)

Modules:
- [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-modules/tree/master/networking/tiered_vpc_ng)
- [Intra VPC Security Group Rule](https://github.com/JudeQuintana/terraform-modules/tree/master/networking/intra_vpc_security_group_rule_for_tiered_vpc_ng)
- [Transit Gateway Centralized Router](https://github.com/JudeQuintana/terraform-modules/tree/master/networking/transit_gateway_centralized_router_for_tiered_vpc_ng)

Main:
- [Networking Trifecta Demo](https://github.com/JudeQuintana/terraform-main/tree/main/networking_trifecta_demo)
  - See [Trifecta Demo Time](/posts/tnt/#trifecta-demo-time) for instructions.
