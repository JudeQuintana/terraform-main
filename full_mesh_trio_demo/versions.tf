terraform {
  required_version = "~>1.3" # allows 1.3, 1.4, 1.x.x
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.31"
    }
  }
}
