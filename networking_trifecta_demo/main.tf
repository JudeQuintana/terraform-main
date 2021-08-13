provider "aws" {
  region = var.base_region

  #https://github.com/hashicorp/terraform-provider-aws/issues/19583
  #default_tags {
  #tags = {
  #Environment = var.env_prefix
  #}
  #}
}
