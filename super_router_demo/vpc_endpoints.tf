# at scale we're saving money right here
locals {
  vpc_endpoint_service_name_fmt = "com.amazonaws.%s.s3"
  vpc_endpoint_type             = "Gateway"
  vpcs_use1_all                 = merge(module.vpcs_use1, module.vpc_another_use1)
}

resource "aws_vpc_endpoint" "s3_use1" {
  providers = {
    aws = aws.use1
  }

  for_each = local.vpcs_use1_all

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

locals {
  vpcs_usw2_all = merge(module.vpcs_usw2, module.vpc_another_usw2)
}

resource "aws_vpc_endpoint" "s3_usw2" {
  providers = {
    aws = aws.usw2
  }

  for_each = local.vpcs_usw2_all

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

