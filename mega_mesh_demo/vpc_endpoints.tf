# at scale we're saving money right here
locals {
  vpc_endpoint_service_name_fmt = "com.amazonaws.%s.s3"
  vpc_endpoint_type             = "Gateway"
}

resource "aws_vpc_endpoint" "s3_apne1" {
  provider = aws.apne1

  for_each = module.vpcs_apne1

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

resource "aws_vpc_endpoint" "s3_apse1" {
  provider = aws.apse1

  for_each = module.vpcs_apse1

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

resource "aws_vpc_endpoint" "s3_cac1" {
  provider = aws.cac1

  for_each = module.vpcs_cac1

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

resource "aws_vpc_endpoint" "s3_euc1" {
  provider = aws.euc1

  for_each = module.vpcs_euc1

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

resource "aws_vpc_endpoint" "s3_euw1" {
  provider = aws.euw1

  for_each = module.vpcs_euw1

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

resource "aws_vpc_endpoint" "s3_sae1" {
  provider = aws.sae1

  for_each = module.vpcs_sae1

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

resource "aws_vpc_endpoint" "s3_use1" {
  provider = aws.use1

  for_each = module.vpcs_use1

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

resource "aws_vpc_endpoint" "s3_use2" {
  provider = aws.use2

  for_each = module.vpcs_use2

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

resource "aws_vpc_endpoint" "s3_usw1" {
  provider = aws.usw1

  for_each = module.vpcs_usw1

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

resource "aws_vpc_endpoint" "s3_usw2" {
  provider = aws.usw2

  for_each = module.vpcs_usw2

  vpc_id            = each.value.id
  service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
  vpc_endpoint_type = local.vpc_endpoint_type
  route_table_ids   = each.value.private_route_table_ids
}

