locals {
  # blackhole cidr app1 usw2b haproxy2 public subnet both super routers
  blackhole = {
    cidrs = ["10.0.31.64/26"]
  }
}
