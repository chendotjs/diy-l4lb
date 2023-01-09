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

  // We are implementing LB in NAT mode. In the future we can try DSR.
  // 1. DNAT: replace destination address with CLIENT or BACKEND, by judging direction.
  if (iph->saddr == IP_ADDRESS(CLIENT))
  {
    iph->daddr = IP_ADDRESS(BACKEND_A);
    eth->h_dest[ETH_ALEN - 1] = BACKEND_A;
  }
  else /* if the saddr is BACKEND */
  {
    iph->daddr = IP_ADDRESS(CLIENT);
    eth->h_dest[ETH_ALEN - 1] = CLIENT;
  }
  // 2. SNAT: replace source address with LB's vip.
  iph->saddr = IP_ADDRESS(LB);
  eth->h_source[ETH_ALEN - 1] = LB;

  iph->check = iph_csum(iph);

  return XDP_TX;
}

char __license[] SEC("license") = "Dual MIT/GPL";
