## Networking Trifecta Demo
Blog Post:
[Terraform Networking Trifecta ](https://jq1.io/posts/tnt/)

All the modules in this project have been [published](https://jq1.io/posts/finally_published_to_public_registry/) to the Terraform Cloud
Public Registry and used in this demo.

# Goal
Using the latest Terraform (v1.3+) and AWS Provider (v4.20.0+)
to route between 3 VPCs with different IPv4 CIDR ranges (RFC 1918)
using a Transit Gateway AKA a hub spoke topology.

- App VPC Tier: `10.0.0.0/20` (Class A Private Internet)
- CICD VPC Tier: `172.16.0.0/20` (Class B Private Internet)
- General VPC Tier: `192.168.0.0/20` (Class C Private Internet)

Example VPC-NG architecture subnets:
![vpc-ng](https://jq1-io.s3.amazonaws.com/base/aws-vpc.png)

The resulting architecture is a hub spoke topology (zoom out):
![tnt](https://jq1-io.s3.amazonaws.com/tnt/tnt.png)

Modules:
- [Tiered VPC-NG](https://github.com/JudeQuintana/terraform-modules/tree/master/networking/tiered_vpc_ng)
- [Intra VPC Security Group Rule](https://github.com/JudeQuintana/terraform-modules/tree/master/networking/intra_vpc_security_group_rule_for_tiered_vpc_ng)
- [Transit Gateway Centralized Router](https://github.com/JudeQuintana/terraform-modules/tree/master/networking/transit_gateway_centralized_router_for_tiered_vpc_ng)

Main:
- [Networking Trifecta Demo](https://github.com/JudeQuintana/terraform-main/tree/main/networking_trifecta_demo)
  - See [Trifecta Demo Time](https://jq1.io/posts/tnt/#trifecta-demo-time) for instructions.

# Caveats
The modules build resources that will cost some money but should be minimal for the demo. (ie NATGW, EIP, TGW)

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
    - Full teardown (destroy) works fine.

# Trifecta Demo Time

**This will be a demo of the following:**
- Configure `us-west-2a` and `us-west-2b` AZs in `app` VPC - `10.0.0.0/20`
  - Launch `app-public` instance in public subnet.
- Configure `us-west-2b` AZ with NATGW in `cicd` VPC - `172.16.0.0/20`
  - Launch `cicd-private` instance in private subnet.
- Configure `us-west-2c` AZ in `general` VPC - `192.168.0.0/20`
  - Launch `general-private` instance in private subnet.
- Configure security groups for access across VPCs.
  - Allow ssh and ping.
- Configure routing between all public and private subnets accross VPCs
via TGW.
- Verify connectivity with `t2.micro` EC2 instances.
- Minimal assembly required.

**Pre-requisites:**
- git
- curl
- Terraform 1.3.0+
- Pre-configured AWS credentials
  - An AWS EC2 Key Pair should already exist in the `us-west-2` region and the private key should have
user read only permissions.
    - private key saved as `~/.ssh/my-ec2-key.pem` on local machine.
    - must be user read only permssions `chmod 400 ~/.ssh/my-ec2-key.pem`

**Assemble the Trifecta** by cloning the [Networking Trifecta Demo](https://github.com/JudeQuintana/terraform-main/) repo.
```
$ git clone git@github.com:JudeQuintana/terraform-main.git
$ cd networking_trifecta_demo
```

Update the `var.base_ec2_instance_attributes.key_name` in [variables.tf](https://github.com/JudeQuintana/terraform-main/blob/main/networking_trifecta_demo/variables.tf#L21) with the EC2 key pair name you're using for the `us-west-2` region (see pre-requisites above).
```
# snippet
variable "base_ec2_instance_attributes" {
  ...
  default = {
    key_name      = "my-ec2-key"            # EC2 key pair name to use when launching an instance
    ami           = "ami-0518bb0e75d3619ca" # AWS Linux 2 us-west-2
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
- Build security groups rules to allow ssh and ping across VPCs.
- Launch instances in each enabled AZ for all VPCs.
- Route between VPCs via TGW.
```
$ terraform apply -target module.intra_vpc_security_group_rules -target aws_instance.instances -target module.centralized_router
```

Once the apply is complete, it will take 1-2 minutes for the TGW
routing to fully propagate.

**Verify Connectivity Between VPCs**
```
$ chmod u+x ./scripts/get_instance_info.sh
$ ./scripts/get_instance_info.sh
```

Example output:
```
# module.vpcs["app"].aws_vpc.this
    default_security_id =  "sg-12345678"

# aws_instance.instances["app-public"]
    private_ip                           = "10.0.3.200"
    public_ip                            = "54.187.241.115"

# aws_instance.instances["general-private"]
    private_ip                           = "192.168.10.8"

# aws_instance.instances["cicd-private"]
    private_ip                           = "172.16.5.11"

# My Public IP
XX.XX.XX.XX

# If you have awscli configured follow the instructions below otherwise you have to do it manually in the AWS console
# AWS CLI Command to copy ("q" to exit returned output):

aws ec2 authorize-security-group-ingress --region us-west-2 --group-id  "sg-12345678" --protocol tcp --port 22 --cidr XX.XX.XX.XX/32
```

Run the `awscli` command from the output above to add an inbound ssh rule from "My Public IP" to the default security group id of the App VPC.

Next, ssh to the `app-public` instance public IP (ie `54.187.241.115`) using the EC2 key pair private key.

Then, ssh to the `private_ip` of the `general-private` instance, then ssh to `cicd-private`, then ssh back to `app-public`.
```
$ ssh -i ~/.ssh/my-ec2-key.pem -A ec2-user@54.187.241.115

[ec2-user@app-public ~]$ ping google.com # works! via igw
[ec2-user@app-public ~]$ ping 192.168.10.8 # works! via tgw
[ec2-user@app-public ~]$ ssh 192.168.10.8

[ec2-user@general-private ~]$ ping google.com # doesn't work! no natgw
[ec2-user@general-private ~]$ ping 172.16.5.11 # works! via tgw
[ec2-user@general-private ~]$ ssh 172.16.5.11

[ec2-user@cicd-private ~]$ ping google.com # works! via natgw
[ec2-user@cicd-private ~]$ ping 10.0.3.200 # works! via tgw
[ec2-user@cicd-private ~]$ ssh 10.0.3.200

[ec2-user@app-public ~]$
```

🔻 Trifecta Complete!!!

**Clean Up**
```
$ terraform destroy
```

