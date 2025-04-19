# at scale we're saving money right here
locals {
  vpc_endpoint_service_name_fmt = "com.amazonaws.%s.s3"
  vpc_endpoint_type             = "Gateway"
}

resource "aws_vpc_endpoint" "s3" {
  providers = {
    aws = aws.use1
  }

  for_each = module.vpcs_use1

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

locals {
  vpcs_use2 = { for this in module.vpcs_use2 : this.name => this }
}

resource "aws_vpc_endpoint" "s3" {
  providers = {
    aws = aws.use2
  }

  for_each = module.vpcs_use2

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

locals {
  vpcs_usw2 = { for this in module.vpcs_usw2 : this.name => this }
}

resource "aws_vpc_endpoint" "s3" {
  providers = {
    aws = aws.usw2
  }

  for_each = module.vpcs_usw2

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

