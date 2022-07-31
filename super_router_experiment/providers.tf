provider "aws" {
  region = var.base_region
}

provider "aws" {
  alias  = "usw2"
  region = var.base_region
}

provider "aws" {
  alias  = "use1"
  region = var.cross_region
}
