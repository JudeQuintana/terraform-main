locals {
  # blackhole cidrs on all centralized routers and both super routers
  # dont need to blackhole isolated subnet cidrs because their route table will have not routes within the Regional IR or Domain IR
  blackhole = {
    # general2 usw2a experiment2 ipv4 private subnet
    cidrs = ["10.0.31.64/26"]
    # cicd2  use1a random1 ipv6 public subnet
    ipv6_cidrs = ["2600:1f28:3d:c706::/64"]
  }
}
