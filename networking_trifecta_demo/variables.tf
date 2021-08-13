variable "env_prefix" {
  default = "test"
}

variable "base_region" {
  default = "us-west-2"
}

variable "base_ec2_instance_attributes" {
  description = "base attributes for building in us-west-2"
  type = object({
    ami           = string
    key_name      = string
    instance_type = string
  })
  default = {
    ami           = "ami-0518bb0e75d3619ca" # AWS Linux 2 us-west-2
    key_name      = "test-jude"             # EC2 key pair name to use when launching an instance
    instance_type = "t2.micro"
  }
}

variable "region_az_labels" {
  type = map(string)

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
