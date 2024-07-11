## Networking Trifecta Demo

# Goal
Using the latest Terraform (v1.3+) and AWS Provider (v4.20.0+)
to route between 3 VPCs with different IPv4 CIDR ranges (RFC 1918) and
IPv6 with IPAM using a Transit Gateway.

Preq:
- IPAM with IPv4 and IPv6 address pools

VPC CIDR Allocations:
- App VPC Tier:
  - IPv4 `10.0.0.0/20` (Class A Private Internet)
  - IPv4 Secondaries `10.1.0.0/18` and `10.2.0.0/18`
  - IPv6 `2600:1f24:66:c000::/56`
- General VPC Tier:
  - IPv4 `192.168.0.0/20` (Class C Private Internet)
  - No IPv4 Secondaries
  - IPv6 `2600:1f24:66:c100::/56`
- CICD VPC Tier:
  - IPv4 `172.16.0.0/20` (Class B Private Internet)
  - IPv4 Secondaries: `172.19.0.0/18`
  - IPv6 `2600:1f24:66:c200::/56`

Dual Stack architecture reference:
- [dual stack ipv6 architectures for aws and hybrid networks](https://aws.amazon.com/blogs/networking-and-content-delivery/dual-stack-ipv6-architectures-for-aws-and-hybrid-networks/)
- [dual stack vpc with multiple ipv6 cidr blocks](https://aws.amazon.com/blogs/networking-and-content-delivery/architect-dual-stack-amazon-vpc-with-multiple-ipv6-cidr-blocks/)

The resulting architecture is a ipv4 only or a dual stack hub and spoke topology (zoom out):
![tnt](https://jq1-io.s3.amazonaws.com/tnt/tnt.png)

# Pre-reqs
- manually created ipam pools (advanced tier) in AWS UI
  - detail IPAM configuration here TODO
- You need to make your own IPv6 IPAM pools since my AWS Account owns
  these specific IPv6 CIDRs (ie subnet your own) so the demo will not
  work as is with other AWS accounts.

# Trifecta Demo Time

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
- git
- curl
- Terraform 1.4.0+
- Pre-configured AWS credentials
  - An AWS EC2 Key Pair should already exist in the `us-west-2` region and the private key should have
user read only permissions.
    - private key saved as `~/.ssh/my-ec2-key.pem` on local machine.
    - must be user read only permssions `chmod 400 ~/.ssh/my-ec2-key.pem`
- IPAM preconfigured with a pool that allows multiple IPv6 /56 addresses
  for a VPC.

**Assemble the Trifecta** by cloning the [Networking Trifecta Demo](https://github.com/JudeQuintana/terraform-main/) repo.
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

The VPCs must be applied first:
```
$ terraform init
$ terraform apply -target module.vpcs
```

Now we'll:
- Build security groups rules to allow ssh and ping across VPCs for both
  IPv4 and IPv6 CIDRs.
- Launch instances in each enabled AZ for all VPCs.
- Route between VPCs via TGW.
```
$ terraform apply -target module.intra_vpc_security_group_rules -target module.ipv6_intra_vpc_security_group_rules -target aws_instance.instances -target module.centralized_router
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
    default_security_group_id =  "sg-0a9cf13b2fbbaebce"

# aws_instance.instances["app-public"]
    private_ip                           = "10.0.3.8"
    public_ip                            = "54.202.27.173"
    ipv6_addresses                       = [
        "2600:1f24:66:c000:c173:5dde:e3da:e64f",
    ]

# aws_instance.instances["general-private"]
    private_ip                           = "192.168.10.119"
    ipv6_addresses                       = [
        "2600:1f24:66:c100:61d5:285f:4b36:52af",
    ]

# aws_instance.instances["cicd-private"]
    private_ip                           = "172.16.5.205"
    ipv6_addresses                       = [
        "2600:1f24:66:c200:8d7d:5ec:b717:df5c",
    ]

# My Public IP
XX.XX.XX.XX

# If you have awscli configured follow the instructions below otherwise you have to do it manually in the AWS console
# AWS CLI Command to copy ("q" to exit returned output):

aws ec2 authorize-security-group-ingress --region us-west-2 --group-id  "sg-0e7180da18aa954e0" --protocol tcp --port 22 --cidr XX.XX.XX.XX/32
```

Run the `awscli` command from the output above to add an inbound ssh rule from "My Public IP" to the default security group id of the App VPC.

Next, ssh to the `app-public` instance public IP (ie `54.202.27.173`) using the EC2 key pair private key.

Then, ssh to the `private_ip` of the `general-private` instance, then ssh to `cicd-private`, then ssh back to `app-public`.

IPv4:
```
$ ssh -i ~/.ssh/my-ec2-key.pem -A ec2-user@54.202.27.173

[ec2-user@app-public ~]$ ping google.com # works! via igw
[ec2-user@app-public ~]$ ping 192.168.10.119 # works! via tgw
[ec2-user@app-public ~]$ ssh 192.168.10.119

[ec2-user@general-private ~]$ ping google.com # doesn't work! no natgw
[ec2-user@general-private ~]$ ping 172.16.5.205 # works! via tgw
[ec2-user@general-private ~]$ ssh 172.16.5.205

[ec2-user@cicd-private ~]$ ping google.com # works! via natgw
[ec2-user@cicd-private ~]$ ping 10.0.3.8 # works! via tgw
[ec2-user@cicd-private ~]$ ssh 10.0.3.8

[ec2-user@app-public ~]$
```

IPv6:
Note - If you want to ssh (`-6` flag) to app-public's ipv6 address, your client
must also have a ipv6 address and another inbound rule must added to the
app vpc default security group id from the clien'ts ipv6 address. Here
we'll ssh via IPv4 first then test IPv6 internally.
```
$ ssh -i ~/.ssh/my-ec2-key.pem -A ec2-user@54.202.27.173

[ec2-user@app-public ~]$ ping6 google.com # works! via igw
[ec2-user@app-public ~]$ ping6 2600:1f24:66:c100:61d5:285f:4b36:52af # works! via tgw
[ec2-user@app-public ~]$ ssh -6 2600:1f24:66:c100:61d5:285f:4b36:52af

[ec2-user@general-private ~]$ ping6 google.com # doesn't work! not opted-in to eigw
[ec2-user@general-private ~]$ ping6 2600:1f24:66:c200:8d7d:5ec:b717:df5c # works! via tgw
[ec2-user@general-private ~]$ ssh -6 2600:1f24:66:c200:8d7d:5ec:b717:df5c

[ec2-user@cicd-private ~]$ ping6 google.com # works! via eigw opt-in
[ec2-user@cicd-private ~]$ ping6 2600:1f24:66:c000:c173:5dde:e3da:e64f # works! via tgw
[ec2-user@cicd-private ~]$ ssh -6 2600:1f24:66:c000:c173:5dde:e3da:e64f

[ec2-user@app-public ~]$
```
🔻 Trifecta Complete!!!

**Clean Up**
`$ terraform destroy`

# Caveats
The modules build resources that will cost some money but should be minimal for the demo.

Even though you can delete subnets in a VPC, remember that the NAT Gateways get created in the public subnets labeled as special for the AZ and is used for VPC attachments when passed to a Centralized Router.

No overlapping CIDR detection or validation since the AWS provider will take care of that.

When modifying an AZ or VPCs in an existing configuration with a TGW Centralized Router:
  - Adding an AZ or VPC.
    - The VPCs must be applied first.
    - Then apply Intra Security Groups Rules and TGW Centralized Router.
  - Removing
    - An AZ being removed must have it's (special) public subnet for the AZ manually removed (modified) from the TGW VPC attachment then wait until state goes from `Modifying` to `Available` before applying (destroying) the AZ.
    - A VPC being removed must have it's TGW attachment manually deleted then wait until state goes from `Deleting` to `Deleted` before applying (destroying) the VPC.
      - Then apply Centralized Router to clean up routes in other VPCs that were pointing to the VPC that was deleted.
        - Terraform should detect the manually deleted resources for vpc attachment, route table assocition, route propagation, etc and remove them from state.
      - Then apply Intra VPC Security Group Rule to clean up SG Rules for the deleted VPC.
    - Full teardown (destroy) mostly works (see below).

Important:
TF AWS Provider has a bug when a VPC is using an IPv6 allocation from IPAM Advanced Tier. When the VPC is being deleted via Terraform it will time out 15+ min to get a failed apply with `Error: waiting for EC2 VPC IPAM Pool Allocation delete: found resource`. However when actual behavior is that the VPC is deleted but ends up being a failed TF apply with ipam errors. AWS wont release the ipv6 cidr allocations right away (30+ min w/ advanced tier, 24hrs+ with free tier) because it thinks the vpc still exists. Not allowed to manually delete the cidr allocation via console or api so can not release or reuse the allocation until AWS decides to auto release them.

You can Ctrl-C to kill the apply when it tries to delete the vpcs (last
step in destroy) or wait until the apply timeout (it will fail). Then if you apply the vpcs again `terraform apply
-target module.vpcs` then TF will clean up missing VPCs from state. But you'll have to
wait until AWS releases deleted cidrs from IPAM if you want to create
them again.

Found [this]( https://github.com/hashicorp/terraform-provider-aws/issues/31211) bug report.

It does appear aws not releasing the allocation quickly is normal behavior. I can delete the vpc with no failure in the console UI and the allocation is not deleted. So it is a TF AWS provider bug. the possible [workaround](https://github.com/hashicorp/terraform-provider-aws/pull/34628) has yet to be merged. no graceful vpc destroy when using ipam is painful.
