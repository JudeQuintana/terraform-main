provider "aws" {
  region = "us-west-2"

  allowed_account_ids = ["FILL_ME_IN"]

  assume_role {
    role_arn = "FILL_ME_IN"
  }

  #https://github.com/hashicorp/terraform-provider-aws/issues/19583
  #default_tags {
  #tags = {
  #Environment = var.env_prefix
  #}
  #}
}
