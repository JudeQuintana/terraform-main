provider "aws" {
  region = var.base_region_usw2
}

provider "aws" {
  alias  = "usw2"
  region = var.base_region_usw2
}

provider "aws" {
  alias  = "use1"
  region = var.cross_region_use1
}
