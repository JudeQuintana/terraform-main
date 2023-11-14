locals {
  # blackhole cidr app1 usw2b haproxy2 public subnet on all centralized routers
  blackhole_cidrs = ["10.0.31.64/26"]
}
