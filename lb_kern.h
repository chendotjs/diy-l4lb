#include <linux/bpf.h>
#include <linux/ip.h>
#include <linux/in.h>
#include <linux/tcp.h>
#include <linux/if_ether.h>

#include "bpf_helpers.h"
#include "bpf_endian.h"

static inline __sum16 csum_fold(__u32 csum)
{
  __u32 sum = csum;
  sum = (sum & 0xffff) + (sum >> 16);
  sum = (sum & 0xffff) + (sum >> 16);
  return ~sum;
}

static inline __u16 iph_csum(struct iphdr *iph)
{
    iph->check = 0;
    __u32 csum = bpf_csum_diff(0, 0, (unsigned int *)iph, sizeof(struct iphdr), 0);
    return csum_fold(csum);
}