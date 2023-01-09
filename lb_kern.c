#include "lb_kern.h"

#define IP_ADDRESS(x) (unsigned int)(172 + (255 << 8) + (255 << 16) + (x << 24))

#define CLIENT 3
#define LB 4
#define BACKEND_A 5
#define BACKEND_B 6

SEC("xdp")
int xdp_load_balancer(struct xdp_md *ctx)
{
  void *data = (void *)(unsigned long)(ctx->data);
  void *data_end = (void *)(unsigned long)(ctx->data_end);

  struct ethhdr *eth = data;
  if (eth + 1 > data_end)
    return XDP_PASS;

  if (bpf_ntohs(eth->h_proto) != ETH_P_IP)
    return XDP_PASS;

  struct iphdr *iph = (void *)(eth + 1);
  if (iph + 1 > data_end)
    return XDP_PASS;

  if (iph->protocol != IPPROTO_TCP)
    return XDP_PASS;

  struct tcphdr *tcph = (void *)(iph + 1);
  if (tcph + 1 > data_end)
    return XDP_PASS;

  bpf_printk("Got packet from %x:%d", iph->saddr, bpf_ntohs(tcph->source));

  return XDP_PASS;
}

char __license[] SEC("license") = "Dual MIT/GPL";
