#include "lb_kern.h"

SEC("xdp")
int xdp_load_balancer(struct xdp_md *ctx)
{
  return XDP_PASS;
}


char __license[] SEC("license") = "Dual MIT/GPL";
