#demo

set your pre-defined ec2-key pair for each region in variables.tf

```
variable "base_ec2_instance_attributes_usw2" {
  description = "base attributes for building in us-west-2"
  type = object({
    ami           = string
    key_name      = string
    instance_type = string
  })
  default = {
    key_name      = "tnt-demo-usw2"         # EC2 key pair name to use when launching an instance
    ami           = "ami-0518bb0e75d3619ca" # AWS Linux 2 us-west-2
    instance_type = "t2.micro"
  }
}

variable "base_ec2_instance_attributes_use1" {
  description = "base attributes for building in us-west-2"
  type = object({
    ami           = string
    key_name      = string
    instance_type = string
  })
  default = {
    key_name      = "my-ec2-key-use1"       # EC2 key pair name to use when launching an instance
    ami           = "ami-0742b4e673072066f" # AWS Linux 2 us-east-1
    instance_type = "t2.micro"
  }
}
```

# VPCs must be applied first
terraform apply -target module.vpcs_usw2 -target module.vpcs_use1

# launch centralized routers, intra-vpcs security groups and instances
terraform apply -target module.tgw_centralized_router_usw2 -target module.tgw_centralized_router_use1 -target module.intra_vpc_security_group_rules_usw2 -target module.intra_vpc_security_group_rules_use1 -target aws_instance.instances_use1 -target aws_instance. instances_usw2

# launch super router
terraform apply  -target module.tgw_super_router_usw2

- manually set sg groups to receive inbound ssh and ping from vpc
  network in other tgw (cross-region) on each side, i should add raw sg
group resource for this in main tf but need to create a module in the
end.
- ssh to public ip for  `app-public-usw2`
- should be able to ssh to internal ip of `general-public-use1`
