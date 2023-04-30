variable "env_prefix" {
  description = "environment prefix ie test, stg, prod"
  type        = string
  default     = "test"
}

variable "base_region_usw2" {
  description = "base region/same acct"
  type        = string
  default     = "us-west-2"
}

variable "cross_region_use1" {
  description = "cross region/same acct"
  type        = string
  default     = "us-east-1"
}

variable "region_az_labels" {
  description = "Update this map with regions and AZs that will be in use for short name labeling"
  type        = map(string)

  default = {
    us-east-1  = "use1"
    us-east-1a = "use1a"
    us-east-1b = "use1b"
    us-east-1c = "use1c"
    us-west-2  = "usw2"
    us-west-2a = "usw2a"
    us-west-2b = "usw2b"
    us-west-2c = "usw2c"
  }
}
