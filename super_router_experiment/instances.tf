locals {
  # create a vpc_name map so I can call vpcs by name so i dont have
  # to type it as a string in places that i need it.
  # ie local.tiered_vpc_names.app will be "app"
  tiered_vpc_names_usw2 = { for vpc_name, this in module.vpcs_usw2 : vpc_name => vpc_name }

  instances_usw2 = [
    {
      # app-public usw2
      name = format("%s-public-usw2", local.tiered_vpc_names_usw2.app)
      # lookup the first public subnet id that belongs to AZ 'a' in the 'app' VPC in usw2
      subnet_id = lookup(lookup(module.vpcs_usw2, local.tiered_vpc_names_usw2.app).az_to_public_subnet_ids, "a")[0]
      vpc_security_group_ids = [
        lookup(module.vpcs_usw2, local.tiered_vpc_names_usw2.app).default_security_group_id,
        lookup(module.vpcs_usw2, local.tiered_vpc_names_usw2.app).intra_vpc_security_group_id
      ]
    },
  ]

  tiered_vpc_names_use1 = { for vpc_name, this in module.vpcs_use1 : vpc_name => vpc_name }

  instances_use1 = [
    {
      # general-private cross region
      name = format("%s-public-use1", local.tiered_vpc_names_use1.general)
      # lookup the first public subnet id that belongs to AZ 'c' in the 'general' VPC in use1
      subnet_id = lookup(lookup(module.vpcs_use1, local.tiered_vpc_names_use1.general).az_to_private_subnet_ids, "c")[0]
      vpc_security_group_ids = [
        lookup(module.vpcs_use1, local.tiered_vpc_names_use1.general).default_security_group_id,
        lookup(module.vpcs_use1, local.tiered_vpc_names_use1.general).intra_vpc_security_group_id
      ]
    }
  ]
}

# The .ssh/config is forwarding the private key to any host
# so you can easily ssh to each instance since instances are
# ssh key only.
# It's a very insecure configuration and is used just for this demo
# and shouldn't be used in production.
resource "aws_instance" "instances_usw2" {
  provider = aws.usw2

  for_each = { for i in local.instances_usw2 : i.name => i }

  ami                    = var.base_ec2_instance_attributes_usw2.ami
  instance_type          = var.base_ec2_instance_attributes_usw2.instance_type
  key_name               = var.base_ec2_instance_attributes_usw2.key_name
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

resource "aws_instance" "instances_use1" {
  provider = aws.use1

  for_each = { for i in local.instances_use1 : i.name => i }

  ami                    = var.base_ec2_instance_attributes_use1.ami
  instance_type          = var.base_ec2_instance_attributes_use1.instance_type
  key_name               = var.base_ec2_instance_attributes_use1.key_name
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
