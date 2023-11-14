# base region
provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias  = "usw2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "use2"
  region = "us-east-2"
}
