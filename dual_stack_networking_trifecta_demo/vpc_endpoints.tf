# at scale we're saving money right here
locals {
  vpcs_with_private_route_table_ids = { for this in module.vpcs : this.name => this if length(this.private_route_table_ids) > 0 }
}

resource "aws_vpc_endpoint" "s3" {
  for_each = local.vpcs_with_private_route_table_ids

  vpc_id            = each.value.id
  service_name      = format("com.amazonaws.%s.s3", each.value.region)
  vpc_endpoint_type = "Gateway"
  route_table_ids   = each.value.private_route_table_ids
}

