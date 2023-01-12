locals {
  # create a vpc_name map so I can call vpcs by name so i dont have
  # to type it as a string in places that i need it.
  # ie local.tiered_vpc_names.app will be "app"
  tiered_vpc_names = { for vpc_name, this in module.vpcs : vpc_name => vpc_name }

  instances = [
    {
      # app-public
      name = format("%s-public", local.tiered_vpc_names.app)
      # lookup the public subnet id for the 'random2' subnet in the 'a' AZ for the 'app' VPC
      subnet_id = lookup(lookup(module.vpcs, local.tiered_vpc_names.app).subnet_name_to_subnet_id, "random1")
      vpc_security_group_ids = [
        lookup(module.vpcs, local.tiered_vpc_names.app).default_security_group_id,
        lookup(module.vpcs, local.tiered_vpc_names.app).intra_vpc_security_group_id
      ]
    },
    {
      # cicd-private
      name = format("%s-private", local.tiered_vpc_names.cicd)
      # lookup the private subnet id for the 'jenkins1' subnet in AZ 'b' for the 'cicd' VPC
      subnet_id = lookup(lookup(module.vpcs, local.tiered_vpc_names.cicd).subnet_name_to_subnet_id, "jenkins1")
      vpc_security_group_ids = [
        lookup(module.vpcs, local.tiered_vpc_names.cicd).default_security_group_id,
        lookup(module.vpcs, local.tiered_vpc_names.cicd).intra_vpc_security_group_id
      ]
    },
    {
      # general-private
      name = format("%s-private", local.tiered_vpc_names.general)
      # lookup the private subnet id for the 'random2' subnet in AZ 'c' for the 'general' VPC
      subnet_id = lookup(lookup(module.vpcs, local.tiered_vpc_names.general).subnet_name_to_subnet_id, "random2")
      vpc_security_group_ids = [
        lookup(module.vpcs, local.tiered_vpc_names.general).default_security_group_id,
        lookup(module.vpcs, local.tiered_vpc_names.general).intra_vpc_security_group_id
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

  ami                    = var.base_ec2_instance_attributes.ami
  instance_type          = var.base_ec2_instance_attributes.instance_type
  key_name               = var.base_ec2_instance_attributes.key_name
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
    Name = each.value.name
  }
}
