variable "env_prefix" {
  description = "environment prefix ie test, stg, prod"
  type        = string
  default     = "test"
}

variable "base_region" {
  description = "base region"
  type        = string
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
    key_name      = "my-ec2-key"            # EC2 key pair name to use when launching an instance in us-west-2
    ami           = "ami-06efb824bfe850db6" # AWS Linux 2023 us-west-2 HVM 64-bit x86
    instance_type = "t2.micro"
  }
}

variable "region_az_labels" {
  description = "Update this map with regions and AZs that will be in use for short name labeling"
  type        = map(string)
  default = {
    us-west-2  = "usw2"
    us-west-2a = "usw2a"
    us-west-2b = "usw2b"
    us-west-2c = "usw2c"
  }
}
