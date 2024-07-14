provider "aws" {
  region = var.base_region_usw2
}

provider "aws" {
  alias  = "usw2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}
