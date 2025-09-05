# Open5GS IPv6 UE Addressing — Findings and Code Pointers

This document summarizes how Open5GS allocates UE IPv6 addresses and delivers them to the UE, with concrete file/function pointers so you can mirror the approach elsewhere.

## Overview
- Allocation uses PFCP-managed per-DNN subnets shared by SMF and UPF.
- IPv6 model: assign a /64 prefix per UE; UE derives a /128 via SLAAC from Router Advertisements (RA) sent by SMF.
- SMF negotiates IPv4/IPv6/IPv4v6; if only one family pool exists, it downshifts accordingly.

## Configuration (examples)
- `configs/open5gs/smf.yaml.in` and `configs/open5gs/upf.yaml.in`
  - IPv6 pool: `- subnet: 2001:db8:cafe::/48` and `gateway: 2001:db8:cafe::1`
  - Ensure gateway IP is configured on a tun/tap:
    - `ip tuntap add name ogstun mode tun`
    - `ip addr add 2001:db8:cafe::1/48 dev ogstun`

## PFCP Pool Mechanics (shared)
- Files: `lib/pfcp/context.h`, `lib/pfcp/context.c`
  - Add/find subnets: `ogs_pfcp_subnet_add()`, `ogs_pfcp_find_subnet_by_dnn()`
  - Generate UE pools: `ogs_pfcp_ue_pool_generate()`
    - IPv6 default prefixlen is 64; builds /128s by copying /64 into `addr[0..1]` and incrementing the IID (`addr[3]`). Skips network and gateway addresses.
  - Allocate/free UE IPs: `ogs_pfcp_ue_ip_alloc()`, `ogs_pfcp_ue_ip_free()`
    - Static IP if input `addr` is non-zero; otherwise dynamic from pool.

## SMF Responsibilities
- Allocation and PAA (IPv6)
  - File: `src/smf/context.c`
    - `smf_sess_set_ue_ip(sess)` negotiates session type, selects IPv6 subnet via `ogs_pfcp_find_subnet_by_dnn(AF_INET6, dnn)`, allocates (`ogs_pfcp_ue_ip_alloc(AF_INET6, ...)`), sets `paa.len = 64` and caches in `ipv6_hash`.
    - If `IPv4v6` requested but only one pool available, downshift to that family with a log.
- Router Advertisement (SLAAC)
  - File: `src/smf/gtp-path.c`
    - Detect RS: `check_if_router_solicit()` (ICMPv6 type 133 inside GTP-U GPDU).
    - Send RA: `send_router_advertisement(sess, ip6_src)` builds RA with `ND_OPT_PREFIX_INFORMATION` (`prefix_len = 64`, A|L flags), optional MTU, and sends as GTP-U to gNB using CP_FUNCTION PDR/FAR.
- Policy interfaces
  - Gx: `src/smf/gx-path.c` sets `Framed-IPv6-Prefix`.
  - PCF: `src/smf/npcf-build.c` sets `ipv6_address_prefix`.

## UPF Responsibilities
- N4 session handling and allocation
  - File: `src/upf/n4-handler.c` → on Session Establishment/Modification, if `pdr->ue_ip_addr_len` set, calls `upf_sess_set_ue_ip(sess, req->pdn_type.u8, pdr)`.
  - File: `src/upf/context.c` → `upf_sess_set_ue_ip()` allocates via `ogs_pfcp_ue_ip_alloc(AF_INET6, ...)` and tracks in `self.ipv6_hash`.
- Tun/Tap setup and device IPs
  - File: `src/upf/gtp-path.c` → `upf_gtp_open()` opens tun/tap and assigns `gateway+subnet` with `ogs_tun_set_ip()` for each PFCP subnet device.
- ND/L2 helpers
  - File: `src/upf/arp-nd.cpp` replies to ICMPv6 Neighbor Solicitation when using TAP (ensures ND works on L2).

## Static IPv6
- Provide a non-zero `addr6` when calling `ogs_pfcp_ue_ip_alloc(AF_INET6, dnn, addr6)` to force static assignment (allocator bypasses pool slot).

## Call Path Summary (IPv6)
1. Session create → SMF picks IPv6 pool and allocates UE /128 (from /64 prefix).
2. SMF installs PDR/FAR so UE→CP ICMPv6 can reach SMF.
3. UE sends RS → SMF detects and sends RA with the UE prefix (/64).
4. UE configures a /128 via SLAAC; UPF forwards user-plane packets between GTP-U and tun/tap according to PDR/FAR.

