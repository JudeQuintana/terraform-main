locals {
  blackhole = {
    cidrs      = ["172.16.65.0/24"]         # app1 jenkins1
    ipv6_cidrs = ["2600:1f26:21:c400::/64"] # app1 test1
  }
}
