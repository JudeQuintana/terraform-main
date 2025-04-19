# at scale we're saving money right here
locals {
  vpc_endpoint_service_name_fmt = "com.amazonaws.%s.s3"
  vpc_endpoint_type             = "Gateway"
}

resource "aws_vpc_endpoint" "s3_use1" {
  provider = aws.use1

  for_each = merge(module.vpcs_use1, module.vpcs_another_use1)

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

resource "aws_vpc_endpoint" "s3_usw2" {
  provider = aws.usw2

  for_each = merge(module.vpcs_usw2, module.vpcs_another_usw2)

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

