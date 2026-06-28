# Context — Infoblox UDDI Demo

Domain vocabulary for this repo. Terms here name the seams worth keeping.

## Terms

**Allocated subnet**
A next-available subnet drawn from a UDDI IPAM address block and reserved back into UDDI as a `bloxone_ipam_subnet`. The `allocated_subnet` module (`modules/allocated_subnet/`) is the deep module that owns this: it hides the `bloxone_ipam_next_available_subnets` data source, the provider's quoted-string quirk (`replace(trimspace(results[0]), "\"", "")`), the CIDR mask assembly, and the reservation resource. Callers learn one interface — `block_id`, `subnet_size`, `space_id`, `name`, `comment`, `parent_cidr`, `tags` — and get back `cidr` (masked, clean), `address` (bare), `subnet_id`, and `parent_cidr` (passthrough).

Invariant: exactly one subnet is allocated per call (`subnet_count = 1`).

**DNS record**
A single DNS record of any supported type (A, AAAA, TXT, CNAME) in a UDDI authoritative zone. The `dns_record` module (`modules/dns_record/`) is the deep module that owns this: it resolves the zone from its FQDN (hiding the `bloxone_dns_auth_zones` data source and the `.results[0].id` quirk), switches the per-type `rdata` shape (`address` / `text` / `cname`), and selects the created record's id. Callers learn one interface — `zone_fqdn`, `record_name`, `record_type`, `record_value`, `ttl`, `comment`, `tags` — and get back `record_id`, `zone_id`, `zone_fqdn`, and `fqdn`. Replaced three fragmented orphan modules (`record_generic`, `record_cname`, `cf_zone`), one of which passed an FQDN where the provider wanted a zone id.
