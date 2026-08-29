terraform {
  required_version = "~>1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.100"
    }
    local = {
      source  = "hashicorp/local"
      version = "~>2.9"
    }
  }
}
