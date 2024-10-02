# Dual Stack Full Mesh Trio Demo

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

Tear down:
 - `terraform destroy`

