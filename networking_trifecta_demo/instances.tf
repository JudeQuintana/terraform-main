locals {
  # a map to look up VPC attributes
  # based on the VPC name. Will use to coorinate
  # buildling EC2 instances in.
  tiered_vpc_attributes = {
    for vpc_name, this in module.usw2_vpcs :
    vpc_name => {
      az_to_private_subnet_ids    = this.az_to_private_subnet_ids
      az_to_public_subnet_ids     = this.az_to_public_subnet_ids
      default_security_group_id   = this.default_security_group_id
      intra_vpc_security_group_id = this.intra_vpc_security_group_id
    }
  }

  # a map to so that i can call vpcs by name from a map so i dont have
  # to type the vpc_name as a string in places i need it.
  # ie local.tiered_vpc_names.app
  tiered_vpc_names = { for vpc_name, this in module.usw2_vpcs : vpc_name => vpc_name }

  instances = [
    {
      name = format("%s-public", local.tiered_vpc_names.app) # app-public
      # lookup the public subnet id that belongs to AZ 'b' in the 'app' VPC
      subnet_id = lookup(lookup(local.tiered_vpc_attributes, local.tiered_vpc_names.app).az_to_public_subnet_ids, "b")[0]
      vpc_security_group_ids = [
        lookup(local.tiered_vpc_attributes, local.tiered_vpc_names.app).default_security_group_id,
        lookup(local.tiered_vpc_attributes, local.tiered_vpc_names.app).intra_vpc_security_group_id
      ]
    },
    {
      name = format("%s-private", local.tiered_vpc_names.db) # db-private
      # lookup the private subnet id that belongs to AZ 'a' in the 'db' VPC
      subnet_id = lookup(lookup(local.tiered_vpc_attributes, local.tiered_vpc_names.db).az_to_private_subnet_ids, "a")[0]
      vpc_security_group_ids = [
        lookup(local.tiered_vpc_attributes, local.tiered_vpc_names.db).default_security_group_id,
        lookup(local.tiered_vpc_attributes, local.tiered_vpc_names.db).intra_vpc_security_group_id
      ]
    },
    {
      name = format("%s-private", local.tiered_vpc_names.general) # general-private
      # lookup the private subnet id that belongs to AZ 'c' in the 'general' VPC
      subnet_id = lookup(lookup(local.tiered_vpc_attributes, local.tiered_vpc_names.general).az_to_private_subnet_ids, "c")[0]
      vpc_security_group_ids = [
        lookup(local.tiered_vpc_attributes, local.tiered_vpc_names.general).default_security_group_id,
        lookup(local.tiered_vpc_attributes, local.tiered_vpc_names.general).intra_vpc_security_group_id
      ]
    }
  ]
}

# The .ssh/config is forwarding the private key to any host
# so you can easily ssh to each instance since instances are
# ssh key only.
# It's a very insecure configuration and is used just for this demo
# and shouldn't be used in production.
resource "aws_instance" "instances" {
  for_each = { for i in local.instances : i.name => i }

  ami                    = "ami-0518bb0e75d3619ca" # AWS Linux 2 us-west-2
  instance_type          = "t2.micro"
  key_name               = var.ec2_key_name
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = each.value.vpc_security_group_ids
  user_data              = <<EOF
#!/bin/bash
SSH_CONFIG_PATH=/home/ec2-user/.ssh/config
sudo hostname ${each.value.name}
echo 'Host *' | sudo tee $SSH_CONFIG_PATH
echo ' ForwardAgent yes' | sudo tee -a $SSH_CONFIG_PATH
sudo chmod 400 $SSH_CONFIG_PATH
sudo chown ec2-user:ec2-user $SSH_CONFIG_PATH
EOF
  tags = {
    Name = format("%s", each.value.name)
  }
}
