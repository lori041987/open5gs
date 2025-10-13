# P-CSCF/PCO Setup Notes (Open5GS v2.x)

Date: 2025-09-15

## Scope
This note captures how to configure Open5GS so that the PDN Connectivity Accept contains the “P‑CSCF IPv6 Address” PCO item, plus minimal environment steps to validate it. It intentionally limits scope to just seeing the PCO IE, not full VoLTE service.

## Files Reviewed
- docs/_docs/tutorial/02-VoLTE-setup.md (VoLTE tutorial)
- configs/volte.yaml.in (template with `smf.p-cscf` example)
- configs/vonr.yaml.in (template with `smf.p-cscf` example)
- configs/open5gs/smf.yaml.in (base SMF config; `p-cscf` commented)
- Relevant source references:
  - src/smf/context.c (parses `smf.p-cscf`, builds PCO in `smf_pco_build()`)
  - src/smf/s5c-build.c (attaches built PCO/APCO/ePCO into Create Session Response)
  - src/smf/gn-handler.c and src/smf/s5c-handler.c (UE PCO/APCO handling)

## Key Findings
- The SMF inserts PCO content based on UE requests and SMF config.
- `smf.p-cscf` controls which P‑CSCF IPs are advertised in PCO:
  - IPv4 entries go into the “P‑CSCF IPv4 Address” response if the UE requests it.
  - IPv6 entries go into the “P‑CSCF IPv6 Address” response if the UE requests it.
- Code path (EPC):
  - `src/smf/context.c` → `smf_pco_build()` handles PCO IDs, including:
    - `OGS_PCO_ID_P_CSCF_IPV6_ADDRESS_REQUEST`: replies using `smf_self()->p_cscf6[...]` when present.
  - `src/smf/s5c-build.c`: attaches PCO/APCO/ePCO to GTPv2-C messages (e.g., Create Session Response → PDN Connectivity Accept mapping).
- UE precondition: SMF only includes the P‑CSCF addresses in PCO if the UE actually requests them in its PCO. Most VoLTE UEs do when APN=ims and PDN type is IPv6/IPv4v6.
- Reachability of the P‑CSCF IP is not required to see the field present in PCO; it’s only needed for real SIP registration.

## Minimal Steps to See “P‑CSCF IPv6 Address” in PDN Connectivity Accept
1) Edit `configs/open5gs/smf.yaml.in` and add your P‑CSCF IPv6 under `smf.p-cscf`.

Example snippet:

```
smf:
  session:
    - subnet: 10.45.0.0/16
      gateway: 10.45.0.1
    - subnet: 2001:db8:cafe::/48
      gateway: 2001:db8:cafe::1
  dns:
    - 2001:4860:4860::8888
    - 2001:4860:4860::8844
  mtu: 1400
  p-cscf:
    - 2001:db8:cafe::10
    # - 10.45.0.10  # optional IPv4 P-CSCF; set when you deploy IPv4 IMS
```

2) Ensure the subscriber has an “ims” APN/DNN with PDN type IPv6 or IPv4v6.
3) Restart SMF and attach using the ims APN. Verify in Wireshark NAS ESM “PDN Connectivity Accept” → PCO → “P‑CSCF IPv6 Address: 2001:db8:cafe::10”.

Notes:
- The base `configs/open5gs/smf.yaml.in` has the `p-cscf` block commented; uncomment and set as above.
- The VoLTE/VoNR templates (`configs/volte.yaml.in`, `configs/vonr.yaml.in`) already show a `p-cscf` list; replace placeholders with real IPs.

## Optional: Make the P‑CSCF IPv6 Reachable (for real SIP tests)
- Assign the service IP on the UE IPv6 interface (on the SMF/UPF host):
  - On‑link to UEs via ogstun:
    - `ip -6 addr add 2001:db8:cafe::10/48 dev ogstun`
  - Enable forwarding and allow SIP/TLS from UE subnet (adjust to your firewall):
    - `sysctl -w net.ipv6.conf.all.forwarding=1`
    - `ip6tables -I INPUT -i ogstun -p udp --dport 5060 -j ACCEPT`
    - `ip6tables -I INPUT -i ogstun -p tcp --dport 5060 -j ACCEPT`
    - `ip6tables -I INPUT -i ogstun -p tcp --dport 5061 -j ACCEPT` (TLS)
- Bind Kamailio P‑CSCF to that address in `kamailio_pcscf.cfg`:
  - `listen=udp:[2001:db8:cafe::10]:5060`
  - `listen=tcp:[2001:db8:cafe::10]:5060`
  - `listen=tls:[2001:db8:cafe::10]:5061` (if used)

## Tutorial Applicability
- For just the PCO field: you can skip most of `docs/_docs/tutorial/02-VoLTE-setup.md` (Kamailio DB setup, RTPengine, FoHSS, PCRF/Rx, DNS SRV). Only SMF config and a UE that requests P‑CSCF are needed.
- For actual VoLTE: follow the tutorial’s Kamailio IMS setup and media/QoS sections.

## Git/Kamailio Branch Tip
- Error: `fatal: A branch named '5.3' already exists.` → You already have a local `5.3` branch.
  - Switch: `git switch 5.3`
  - Track upstream: `git branch --set-upstream-to=origin/5.3 5.3`
  - Update: `git pull --ff-only`
  - Hard reset to remote (destructive): `git fetch origin && git switch 5.3 && git reset --hard origin/5.3`

## Code References (for future deep dive)
- `src/smf/context.c`
  - YAML parse of `p-cscf` → fills `self.p_cscf[]` and `self.p_cscf6[]`.
  - `smf_pco_build()` handles:
    - DNS (IPv4/IPv6), IPv4/IPv6 MTU, and P‑CSCF IPv4/IPv6 Address Request.
    - IPv6 case increments a round‑robin index over configured IPv6 P‑CSCF list.
- `src/smf/s5c-build.c`
  - Builds and attaches PCO/APCO/ePCO to Create Session Response (EPC S5/S8).

## Next Steps
- Confirm you want me to apply the `configs/open5gs/smf.yaml.in` edit now (add `p-cscf: [2001:db8:cafe::10]` and keep IPv4 commented).
- If/when you want to test SIP registration, assign the IPv6 to `ogstun` and bind Kamailio as above.
