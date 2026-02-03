terraform {
  required_version = "~>1.4"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # the AWS 6.30+ provider version will also work here but will show minor deprecations that havent been updated
      version = "~>5.100"
    }
  }
}
