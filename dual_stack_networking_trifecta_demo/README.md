# Dual Stack Networking Trifecta Demo
- The dual stack version of the (IPv4 only) [Networking Trifecta demo](https://github.com/JudeQuintana/terraform-main/tree/main/networking_trifecta_demo).
- Demo does not work as-is because these Amazon owned IPv6 CIDRs have been allocated to my AWS account.
- You'll need to configure your own IPv4 and IPv6 cidr pools/subpools.
- Both IPv4 and IPv6 secondary cidrs are supported.
- Start with IPv4 only and add IPv6 at a later time or start with both.

## Goal
Using the latest Terraform (v1.9.0+) and AWS Provider (v5.61.0+)
to route between 3 VPCs with different IPv4 CIDR ranges (RFC 1918) and
IPv6 with IPAM using a Transit Gateway.

VPC CIDRs:
- App VPC Tier:
  - IPv4: `10.0.0.0/18` (Class A Private Internet)
  - IPv4 Secondaries: `10.1.0.0/20`
  - IPv6: `2600:1f24:66:c000::/56`
  - IPv6 Secondaries: `2600:1f24:66:c800::/56`
- General VPC Tier:
  - IPv4: `192.168.0.0/18` (Class C Private Internet)
  - No IPv4 Secondaries
  - IPv6: `2600:1f24:66:c100::/56`
  - No IPv6 Secondaries
- CICD VPC Tier:
  - IPv4: `172.16.0.0/18` (Class B Private Internet)
  - IPv4 Secondaries: `172.19.0.0/20`
  - IPv6: `2600:1f24:66:c200::/56`
  - IPv6 Secondaries: `2600:1f24:66:c600::/56`

VPCs with an IPv4 network cidr /18 provides /20 subnet for each AZ (up to 4 AZs).

Dual Stack architecture reference:
- [dual stack ipv6 architectures for aws and hybrid networks](https://aws.amazon.com/blogs/networking-and-content-delivery/dual-stack-ipv6-architectures-for-aws-and-hybrid-networks/)

The resulting architecture is a ipv4 only or a dual stack hub and spoke topology (zoom out). old pic:
![tnt](https://jq1-io.s3.amazonaws.com/tnt/tnt.png)

## Trifecta Demo Time

**This will be a demo of the following:**
- Configure `us-west-2a` and `us-west-2b` AZs in `app` VPC.
  - Launch `app-public` instance in public subnet.
- Configure `us-west-2c` AZ in `general` VPC.
  - Launch `general-private` instance in private subnet.
- Configure `us-west-2b` AZ with NATGW in `cicd`
  - Launch `cicd-private` instance in private subnet.
- Configure security groups for access across VPCs.
  - Allow ssh and ping.
- Configure routing between all public and private subnets accross VPCs
via TGW.
- Verify connectivity with `t2.micro` EC2 instances.
- Minimal assembly required.

**Pre-requisites:**
- There are many ways to configure IPAM so I manually created IPAM pools (advanced tier) in the AWS UI.
- You need to make your own IPv6 IPAM pools since my AWS Account has allocations from these specific AWS owned IPv6 CIDRs so the demo will not work as is with other AWS accounts.

IPAM Configuration:
- Advanced Tier IPAM in `us-west-2` operating reigon (locale).
  - No IPv4 regional pool at the moment.
  - IPv6 subpool needs a IPv6 regional pool with `/52` to be able to provision `/56` per locale.
  - `us-east-2` (ipam locale)
    - IPv4 Pool (private scope)
        - Provisioned CIDRs:
          - `10.0.0.0/18`
          - `10.1.0.0/20`
          - `172.16.0.0/18`
          - `172.19.0.0/20`
          - `192.168.0.0/18`
    - IPv6 regional pool (public scope)
      - `2600:1f24:66:c000::/52`
        - IPv6 subpool (public scope)
          - Provisioned CIDRs:
          - `2600:1f24:66:c000::/56`
          - `2600:1f24:66:c100::/56`
          - `2600:1f24:66:c200::/56`
          - `2600:1f24:66:c600::/56`
          - `2600:1f24:66:c800::/56`

- Pre-configured AWS credentials
  - An AWS EC2 Key Pair should already exist in the `us-west-2` region and the private key should have
user read only permissions.
    - private key saved as `~/.ssh/my-ec2-key.pem` on local machine.
    - must be user read only permssions `chmod 400 ~/.ssh/my-ec2-key.pem` for a VPC.

**Assemble the Trifecta** by cloning the [Dual Stack Networking Trifecta Demo](https://github.com/JudeQuintana/terraform-main/) repo.
```
$ git clone git@github.com:JudeQuintana/terraform-main.git
$ cd dual_stack_networking_trifecta_demo
```

Update the `var.base_ec2_instance_attributes.key_name` in [variables.tf](https://github.com/JudeQuintana/terraform-main/blob/main/networking_trifecta_demo/variables.tf#L21) with the EC2 key pair name you're using for the `us-west-2` region (see pre-requisites above).
```
# snippet
variable "base_ec2_instance_attributes" {
  ...
  default = {
    key_name      = "my-ec2-key" # EC2 key pair name to use when launching an instance
    instance_type = "t2.micro"
  }
}
```

It begins:
```
terraform init
```

The VPCs must be applied first:
```
terraform apply -target module.vpcs
```

Now we'll:
- Build security groups rules to allow ssh and ping across VPCs for both
  IPv4 and IPv6 CIDRs.
- Launch instances in each enabled AZ for all VPCs.
- Route between VPCs via TGW.
```
terraform apply -target module.intra_vpc_security_group_rules -target module.ipv6_intra_vpc_security_group_rules -target aws_instance.instances -target module.centralized_router
```
or just `$ terraform apply`

**Verify Connectivity Between VPCs**
```
$ chmod u+x ./scripts/get_instance_info.sh
$ ./scripts/get_instance_info.sh
```

Example output:
```
# module.vpcs["app"].aws_vpc.this
    default_security_group_id =  "sg-0ee7dde9d18507107"

# aws_instance.instances["app-public"]
    private_ip                           = "10.0.3.6"
    public_ip                            = "18.237.6.16"
    ipv6_addresses                       = [
        "2600:1f24:66:c000:dc86:f548:a37e:ffed",
    ]

# aws_instance.instances["app-isolated"]
    private_ip                           = "10.1.13.151"
    ipv6_addresses                       = [
        "2600:1f24:66:c85c:1267:484b:a051:67d2",
    ]

# aws_instance.instances["general-private"]
    private_ip                           = "192.168.10.52"
    ipv6_addresses                       = [
        "2600:1f24:66:c100:2cda:88a8:d513:160b",
    ]

# aws_instance.instances["cicd-private"]
    private_ip                           = "172.16.5.189"
    ipv6_addresses                       = [
        "2600:1f24:66:c200:fd3d:d0b8:2aa3:71ca",
    ]

# My Public IP
XX.XX.XX.XX

# If you have awscli configured follow the instructions below otherwise you have to do it manually in the AWS console
# AWS CLI Command to copy ("q" to exit returned output):

aws ec2 authorize-security-group-ingress --region us-west-2 --group-id  "sg-0ee7dde9d18507107" --protocol tcp --port 22 --cidr XX.XX.XX.XX/32
```

Run the `awscli` command from the output above to add an inbound ssh rule from "My Public IP" to the default security group id of the App VPC.

Next, ssh to the `app-public` instance public IP (ie `18.237.6.16`) using the EC2 key pair private key.

Then, ssh to the `private_ip` of the `general-private` instance, then ssh to `cicd-private`, then ssh back to `app-public`.

IPv4:
```
$ ssh -i ~/.ssh/my-ec2-key.pem -A ec2-user@18.237.6.16

[ec2-user@app-public ~]$ ping google.com # works! via igw
[ec2-user@app-public ~]$ ping 192.168.10.52 # works! via tgw
[ec2-user@app-public ~]$ ssh 192.168.10.52

[ec2-user@general-private ~]$ ping google.com # doesn't work! no natgw
[ec2-user@general-private ~]$ ping 172.16.5.189 # works! via tgw
[ec2-user@general-private ~]$ ssh 172.16.5.189

[ec2-user@cicd-private ~]$ ping google.com # works! via natgw
[ec2-user@cicd-private ~]$ ping 10.0.3.6 # works! via tgw
[ec2-user@cicd-private ~]$ ssh 10.0.3.6

[ec2-user@app-public ~]$
```

IPv6:
Note - If you want to ssh (`-6` flag) to `app-public`'s ipv6 address then your client
must also have a ipv6 address and another inbound rule must added to the
app vpc default security group from the client's ipv6 address. Here
we'll ssh via IPv4 first then test IPv6 internally.
```
$ ssh -i ~/.ssh/my-ec2-key.pem -A ec2-user@18.237.6.16

[ec2-user@app-public ~]$ ping6 google.com # works! via igw
[ec2-user@app-public ~]$ ping6 2600:1f24:66:c100:2cda:88a8:d513:160b # works! via tgw
[ec2-user@app-public ~]$ ssh -6 2600:1f24:66:c100:2cda:88a8:d513:160b

[ec2-user@general-private ~]$ ping6 google.com # doesn't work! not opted-in to eigw
[ec2-user@general-private ~]$ ping6 2600:1f24:66:c200:fd3d:d0b8:2aa3:71ca # works! via tgw
[ec2-user@general-private ~]$ ssh -6 2600:1f24:66:c200:fd3d:d0b8:2aa3:71ca

[ec2-user@cicd-private ~]$ ping6 google.com # works! via eigw opt-in
[ec2-user@cicd-private ~]$ ping6 2600:1f24:66:c000:dc86:f548:a37e:ffed # works! via tgw
[ec2-user@cicd-private ~]$ ssh -6 2600:1f24:66:c000:dc86:f548:a37e:ffed

[ec2-user@app-public ~]$
```
🔻 Trifecta Complete!!!

Isolated subnets:
- Are private subnets in a route table with no routes.
- They can only have inter-vpc communication but not to other VPCs even
 when the VPC is in a full mesh configuration.

Example:
```
[ec2-user@app-public ~]$ ping 10.1.13.151 # works!
...
[ec2-user@general-private ~]$ ping 10.1.13.151 # doesn't work!
...
[ec2-user@app-isolated ~]$ ping 10.0.3.6 # works!
[ec2-user@app-isolated ~]$ ping 192.168.10.52 # doesn't work!
[ec2-user@app-isolated ~]$ ping google.com # doesn't work!
```

**Clean Up**
`terraform destroy`
- Full teardown (destroy) works for AWS provider 5.61.0+ but the VPC destroy in the last step will take about 10-30 min to finish deleting cleanly after waiting for AWS to release IPAM pool CIDRs without error. Now you can immediately rebuild with the same cidrs after the destroy without waiting for IPAM like before (see below). Not sure exactly what the fix was.

## Caveats
- Full teardown (destroy) mostly works for AWS provider 5.51.1 and earlier. TF AWS Provider has a bug when a VPC is using an IPv6 allocation from IPAM Advanced Tier. When the VPC is being deleted via Terraform it will time out 15+ min to get a failed apply with `Error: waiting for EC2 VPC IPAM Pool Allocation delete: found resource`. However when actual behavior is that the VPC is deleted but ends up being a failed TF apply with ipam errors. AWS wont release the ipv6 cidr allocations right away (30+ min w/ advanced tier, 24hrs+ with free tier) because it thinks the vpc still exists. Not allowed to manually delete the cidr allocation via console or api so can not release or reuse the allocation until AWS decides to auto release them.
  - You can Ctrl-C to kill the apply when it tries to delete the vpcs (last step in destroy) or wait until the apply timeout (it will fail). Then if you apply the vpcs again `terraform apply -target module.vpcs` then TF will clean up missing VPCs from state. But you'll have to
wait until AWS releases deleted cidrs from IPAM if you want to create them again.
  - Found [this]( https://github.com/hashicorp/terraform-provider-aws/issues/31211) bug report.

  - It does appear aws not releasing the allocation quickly is normal behavior. I can delete the vpc with no failure in the console UI and the allocation is not deleted. So it is a TF AWS provider bug. the possible [workaround](https://github.com/hashicorp/terraform-provider-aws/pull/34628) has yet to be merged. no graceful vpc destroy when using ipam is painful

- The modules build resources that will cost some money but should be minimal for the demo.

- There is no overlapping CIDR detection or validation.

## Version info

Tiered VPC-NG `v1.0.6`:
- minor: public_az_to_subnet_cidrs and isolated_az_to_subnet_cidrs logic not needed but is required for private_az_to_subnet_cidrs because it is used for route table resource creation.

`v1.0.5`:
- support for centralized egress modes when passed to centralized router
  - `central = true` makes VPC the egress VPC
  - `private = true` makes VPC opt in to route private subnet traffic out the egress VPC per AZ
  - outputs for each mode
- new `output.public_natgw_az_to_eip` map of natgw eip per az
- better validation on private and public subnets that have `special = true` attribute set per AZ
  - allows for more fexible building and destroying AZs for the VPC.
- AWS ref: [Centralized Egress](https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/using-nat-gateway-for-centralized-egress.html)
- New [Centralized Egress Dual Stack Full Mesh Trio Demo](https://github.com/JudeQuintana/terraform-main/tree/main/centralized_egress_dual_stack_full_mesh_trio_demo)

`v1.0.4`:
- support for dual stack isolated subnets

`v1.0.3`:
- support for IPv6 secondary cidrs
- aws provider `>=5.61` required

`v1.0.2`:
- Requires IPAM Pools for both IPv4 and IPv6 cidrs.
  - Advanced Tier recommended.
  - Can start with IPv4 only then add IPv6 at a later time, or start with both.
- NATGWs can be built within a public subnet (only one allowed per AZ) with `natgw = true` to route private IPv4 subnets in the same AZ to the internet.
- EIGW is similar to NATGW but for IPv6 subnets but there can only be EIGW per VPC so any AZ with `eigw = true` is opt-in
for private IPv6 subnets per AZ to route to the internet.
- IGW continues to auto toggles based on if public subnets (ipv4 or ipv6) are defined.
- `special = true` can be assigned to a secondary subnet cidr (public or private).
  - Can be used as a vpc attachemnt when passed to centralized router.
  - EIPs dont use a public pool and will continue to be AWS owned public IPv4 cidrs

Centralized Router `v1.0.6`:
- remove legacy output vpc.routes. will rebuild super router at a later time but no need to keep this around.

`v1.0.5`:
- support for VPC centralized egress modes when passed to centralized router with validation
  - when a VPC has `central = true` create `0.0.0.0/0` route on tgw route table
  - when a VPC has `private = true` create `0.0.0.0/0` route on all private subnet route tables.
- It is no longer required for a VPC's AZ to have a private or public subnet with `special = true` but
  if there are subnets with `special = true` then it must be either 1 private or 1 public subnet that has it
  configured per AZ (validation enforced).
- Any VPC that has a private or public subnet with `special = true`, that subnet will be used as
  the VPC attachment for it's AZ when passed to Centralized Router.
- If the VPC does not have any AZs with private or public subnet with `special = true` it will be removed
- AWS ref: [Centralized Egress](https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/using-nat-gateway-for-centralized-egress.html)
- New [Centralized Egress Dual Stack Full Mesh Trio Demo](https://github.com/JudeQuintana/terraform-main/tree/main/centralized_egress_dual_stack_full_mesh_trio_demo)
  from the Centralized Router.

`v1.0.4`:
- ability to gracefully switch between a blackhole route and a static route that have the same cidr/ipv6\_cidr for vpc attachments.

`v1.0.3`:
- support for IPv6 secondary cidrs
- TGW routes for vpc attachments are now static by default instead of
  route propagation.
  - route propagation can be toggled with `propagate_routes = true` but
    the default is false.
- aws provider `>=5.61` required

`v1.0.2`:
- generate routes for VPCs with IPv4 network cidrs, IPv4 secondary cidrs, and IPv6 cidrs.

