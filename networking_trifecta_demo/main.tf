provider "aws" {
  # currently not using default_tags in the AWS provider
  # because the behavior has been inconsistent for me.
  # Which is  why I still use a default tags merging
  # pattern in each module.

  region = var.base_region
}
