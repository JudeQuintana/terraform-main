# Mega Mesh
Mega Mesh == (Full Mesh Trio)² + 1
Full Mesh Transit Gateway across 10 regions.

![mega-mesh](https://jq1-io.s3.amazonaws.com/mega-mesh/ten-full-mesh-tgw.png)

1. It begins
  - `terraform init`
2. Build VPCs (must exist before centralized routers and mega mesh)
  - `terraform apply -target module.vpcs_use1 -target module.vpcs_usw1 -target module.vpcs_euc1 -target module.vpcs_euw1 -target module.vpcs_apne1 -target module.vpcs_apse1 -target module.vpcs_cac1 -target module.vpcs_sae1 -target module.vpcs_use2 -target module.vpcs_usw2`
3. Build Centralized Routers
  - `terraform apply -target module.centralized_router_use1 -target module.centralized_router_usw1 -target module.centralized_router_euc1 -target module.centralized_router_euw1 -target module.centralized_router_apne1 -target module.centralized_router_apse1 -target module.centralized_router_sae1 -target module.centralized_router_use2 -target module.centralized_router_usw2`

4. Build Mega Mesh
  - `terraaform apply -target module.mega_mesh`

Notes:
  - You can combine steps 3 and 4 with `terraform apply`.
  - I have to use direct module repo links for centralized router (etc) because TF public registry is not synching correctly at the moment.
