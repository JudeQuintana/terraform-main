locals {
  vpcs = { for this in module.vpcs : this.name => this }
}

# at scale we're saving money right here
resource "aws_vpc_endpoint" "s3" {
  for_each = local.vpcs

  vpc_id            = each.value.id
  service_name      = format("com.amazonaws.%s.s3", each.value.region)
  vpc_endpoint_type = "Gateway"
  route_table_ids   = each.value.private_route_table_ids
}

