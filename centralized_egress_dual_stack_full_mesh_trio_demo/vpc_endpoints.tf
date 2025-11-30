# at scale we're saving money right here
#locals {
#vpc_endpoint_service_name_fmt = "com.amazonaws.%s.s3"
#vpc_endpoint_type             = "Gateway"

#vpcs_use1_with_private_route_table_ids = { for this in module.vpcs_use1 : this.name => this if length(this.private_route_table_ids) > 0 }
#vpcs_use2_with_private_route_table_ids = { for this in module.vpcs_use2 : this.name => this if length(this.private_route_table_ids) > 0 }
#vpcs_usw2_with_private_route_table_ids = { for this in module.vpcs_usw2 : this.name => this if length(this.private_route_table_ids) > 0 }
#}

#resource "aws_vpc_endpoint" "s3_use1" {
#provider = aws.use1

#for_each = local.vpcs_use1_with_private_route_table_ids

#vpc_id            = each.value.id
#service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
#vpc_endpoint_type = local.vpc_endpoint_type
#route_table_ids   = each.value.private_route_table_ids
#}

#resource "aws_vpc_endpoint" "s3_use2" {
#provider = aws.use2

#for_each = local.vpcs_use2_with_private_route_table_ids

#vpc_id            = each.value.id
#service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
#vpc_endpoint_type = local.vpc_endpoint_type
#route_table_ids   = each.value.private_route_table_ids
#}

#resource "aws_vpc_endpoint" "s3_usw2" {
#provider = aws.usw2

#for_each = local.vpcs_usw2_with_private_route_table_ids

#vpc_id            = each.value.id
#service_name      = format(local.vpc_endpoint_service_name_fmt, each.value.region)
#vpc_endpoint_type = local.vpc_endpoint_type
#route_table_ids   = each.value.private_route_table_ids
#}

