Demo should work. Route intra-region and cross-region (same acct) central router tgws and vpcs via super router tgw.

Validated connectivity with aws network analyzer.
(ec2 usw2 <-> vpc usw2 <-> centralized router usw2 <-> super router usw2 <-> centralized router use1 <-> vpc use1 <-> ec2 use1)

it begins
`terraform init`

VPCs must be applied first
`terraform apply -target module.vpcs_usw2 -target module.vpcs_use1`

launch centralized routers, intra-vpcs security groups and instances
`terraform apply -target module.tgw_centralized_router_usw2 -target module.tgw_centralized_router_use1`

launch super router
`terraform apply  -target module.tgw_super_router_usw2`
