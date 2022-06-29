variable "env_prefix" {
  description = "environment prefix ie test, stg, prod"
  default     = "test"
}

variable "base_region" {
  description = "base region"
  default     = "us-west-2"
}

variable "base_ec2_instance_attributes" {
  description = "base attributes for building in us-west-2"
  type = object({
    ami           = string
    key_name      = string
    instance_type = string
  })
  default = {
    key_name      = "my-ec2-key"            # EC2 key pair name to use when launching an instance
    ami           = "ami-0518bb0e75d3619ca" # AWS Linux 2 us-west-2
    instance_type = "t2.micro"
  }
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
