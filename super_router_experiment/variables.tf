variable "env_prefix" {
  description = "environment prefix ie test, stg, prod"
  default     = "test"
}

variable "base_region" {
  description = "base region/same acct"
  default     = "us-west-2"
}

variable "cross_region" {
  description = "cross region/same acct"
  default     = "us-east-1"
}

variable "region_az_labels" {
  description = "Update this map with regions and AZs that will be in use for short name labeling"
  type        = map(string)

  default = {
    us-east-1  = "use1"
    us-east-1a = "use1a"
    us-west-1  = "usw1"
    us-west-1a = "usw1a"
    us-west-1b = "usw1b"
    us-west-1c = "usw1c"
    us-west-2  = "usw2"
    us-west-2a = "usw2a"
    us-west-2b = "usw2b"
    us-west-2c = "usw2c"
  }
}
