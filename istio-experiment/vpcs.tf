################################################################################
# IPAM and VPC
################################################################################

# ipam was set up manually (advanced tier)
# main ipam in usw2 with a pool for usw2 locale
data "aws_vpc_ipam_pool" "ipv4_usw2" {
  filter {
    name   = "description"
    values = ["ipv4-test-usw2"]
  }

  filter {
    name   = "address-family"
    values = ["ipv4"]
  }
}

locals {
  env_prefix = "test"

  region_az_labels = {
    us-west-2  = "usw2"
    us-west-2a = "usw2a"
    us-west-2b = "usw2b"
    us-west-2c = "usw2c"
  }

  private_subnet_tags = { "kubernetes.io/role/internal-elb" = 1 }
  public_subnet_tags  = { "kubernetes.io/role/elb" = 1 }
  ipv4_ipam_pool_usw2 = data.aws_vpc_ipam_pool.ipv4_usw2
}

# ipv4 and ipv6 must use an ipam pool
# can start with ipv4 only and then add ipv6 later if needed.
locals {
  vpcs_usw2 = [
    {
      name = "app"
      ipv4 = {
        network_cidr = "10.0.0.0/18"
        ipam_pool    = local.ipv4_ipam_pool_usw2
      }
      azs = {
        a = {
          private_subnets = [
            # for later ipv6_cidr = "2600:1f24:66:c008::/64"
            { name = "istio1", cidr = "10.0.0.0/20", tags = local.private_subnet_tags }
          ]
          public_subnets = [
            # for later ipv6_cidr = "2600:1f24:66:c000::/64"
            { name = "istio2", cidr = "10.0.48.0/24", natgw = true, tags = local.public_subnet_tags }
          ]
        }
        b = {
          private_subnets = [
            # for later ipv6_cidr = "2600:1f24:66:c006::/64"
            { name = "istio3", cidr = "10.0.16.0/20", tags = local.private_subnet_tags }
          ]
          public_subnets = [
            # for later ipv6_cidr = "2600:1f24:66:c000::/64"
            { name = "istio4", cidr = "10.0.49.0/24", natgw = true, tags = local.public_subnet_tags }
          ]
        }
        c = {
          private_subnets = [
            # for later ipv6_cidr = "2600:1f24:66:c006::/64"
            { name = "istio5", cidr = "10.0.32.0/20", tags = local.private_subnet_tags }
          ]
          public_subnets = [
            # for later ipv6_cidr = "2600:1f24:66:c000::/64"
            { name = "istio6", cidr = "10.0.50.0/24", natgw = true, tags = local.public_subnet_tags }
          ]
        },
      }
    }
  ]
}

module "vpcs" {
  source  = "JudeQuintana/tiered-vpc-ng/aws"
  version = "1.0.7"

  for_each = { for t in local.vpcs_usw2 : t.name => t }

  env_prefix       = local.env_prefix
  region_az_labels = local.region_az_labels
  tiered_vpc       = each.value
  tags             = local.tags
}

locals {
  vpc_names = { for this in module.vpcs : this.name => this.name }
}
