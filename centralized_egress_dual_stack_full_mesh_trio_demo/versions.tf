terraform {
  required_version = "~>1.4"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # will display minor deprecation messages for the provider until the modules are updated
      version = "~>6.58"
    }
  }
}
