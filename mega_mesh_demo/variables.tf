variable "env_prefix" {
  description = "environment prefix ie test, stg, prod"
  type        = string
  default     = "test"
}

variable "region_az_labels" {
  description = "Update this map with regions and AZs that will be in use for short name labeling"
  type        = map(string)
  default = {
    us-east-1       = "use1"
    us-east-1a      = "use1a"
    us-east-1b      = "use1b"
    us-east-1c      = "use1c"
    us-west-1       = "usw1"
    us-west-1a      = "usw1a"
    us-west-1b      = "usw1b"
    us-west-1c      = "usw1c"
    eu-central-1    = "euc1"
    eu-central-1a   = "euc1a"
    eu-central-1b   = "euc1b"
    eu-central-1c   = "euc1c"
    eu-west-1       = "euw1"
    eu-west-1a      = "euw1a"
    eu-west-1b      = "euw1b"
    eu-west-1c      = "euw1c"
    ap-northeast-1  = "apne1"
    ap-northeast-1a = "apne1a"
    ap-northeast-1b = "apne1b"
    ap-northeast-1c = "apne1c"
    ap-southeast-1  = "apse1"
    ap-southeast-1a = "apse1a"
    ap-southeast-1b = "apse1b"
    ap-southeast-1c = "apse1c"
    ca-central-1    = "cac1"
    ca-central-1a   = "cac1a"
    ca-central-1b   = "cac1b"
    ca-central-1c   = "cac1c"
    ca-central-1d   = "cac1d"
    sa-east-1       = "sae1"
    sa-east-1a      = "sae1a"
    sa-east-1b      = "sae1b"
    sa-east-1c      = "sae1c"
    us-east-2       = "use1"
    us-east-2a      = "use1a"
    us-east-2b      = "use1b"
    us-east-2c      = "use1c"
    us-west-2       = "usw1"
    us-west-2a      = "usw1a"
    us-west-2b      = "usw1b"
    us-west-2c      = "usw1c"
  }
}
