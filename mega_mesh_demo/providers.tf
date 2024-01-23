# base region
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "usw1"
  region = "us-west-1"
}

provider "aws" {
  alias  = "euc1"
  region = "eu-central-1"
}

provider "aws" {
  alias  = "euw1"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "apne1"
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "apse1"
  region = "ap-southeast-1"
}

provider "aws" {
  alias  = "cac1"
  region = "ca-central-1"
}

provider "aws" {
  alias  = "sae1"
  region = "sa-east-1"
}

provider "aws" {
  alias  = "use2"
  region = "us-east-2"
}

provider "aws" {
  alias  = "usw2"
  region = "us-west-2"
}

