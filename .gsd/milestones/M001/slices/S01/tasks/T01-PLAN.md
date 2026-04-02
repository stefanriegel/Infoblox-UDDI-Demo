---
estimated_steps: 5
estimated_files: 2
---

# T01: Create Terraform root for combined IPAM+VPC+DNS demo

**Slice:** S01 — Combined IPAM+DNS Workflow
**Milestone:** M001

## Description

Create the Terraform configuration that chains three UDDI capabilities in one root: IPAM subnet allocation → AWS VPC provisioning → DNS A record creation. This merges proven patterns from `live/demos/vpc-aws/main.tf` (IPAM + VPC) and `live/demos/dns/main.tf` (DNS records) into a single configuration. The key innovation is using `cidrhost(aws_vpc.main.cidr_block, 1)` to derive the DNS record's IP from the allocated subnet — creating a realistic "this VPC's entry point is now DNS-resolvable via UDDI" demo story.

## Steps

1. **Create `live/demos/combined/variables.tf`** — Define superset of variables from both source demos:
   - From vpc-aws: `bloxone_api_key` (sensitive), `vpc_name` (default "uddi-combined-demo"), `subnet_size` (number, default 24, validated 16-28), `aws_region` (default "eu-central-1"), `aws_block_id`, `ipam_space_id`
   - From dns: `zone_fqdn` (default "aws.gh.blox42.rocks.", validated trailing dot), `record_name` (default "combined-demo")
   - Add: `bloxone_host` (default "https://csp.infoblox.com", for provider config)

2. **Create `live/demos/combined/main.tf`** — Build the chained configuration:
   - **Providers block**: `terraform { required_providers { bloxone, aws } }` with version constraints matching existing demos. Configure both providers.
   - **IPAM phase**: `data.bloxone_ipam_next_available_subnets` (from `aws_block_id`, size `subnet_size`) → `resource.bloxone_ipam_subnet` with name and tags
   - **VPC phase**: `aws_vpc` using CIDR from `"${replace(trimspace(tolist(...)[0]), "\"", "")}/${var.subnet_size}"` — replicate exact CIDR construction from vpc-aws to avoid mismatches. Add `aws_internet_gateway`.
   - **DNS phase**: `data.bloxone_dns_auth_zones` to look up zone by FQDN → `resource.bloxone_dns_a_record` with rdata = `cidrhost(aws_vpc.main.cidr_block, 1)` and name_in_zone = `var.record_name`
   - **Tags**: All AWS resources get `demo = "true"`, `automation = "github-actions"`, `Name` tag. IPAM subnet gets comment with demo identification.
   - **Outputs**: `vpc_id`, `vpc_cidr`, `subnet_id` (IPAM), `dns_record_fqdn` (constructed as `"${var.record_name}.${var.zone_fqdn}"`), `dns_record_value` (the IP), `ipam_subnet_address`

3. **Cross-check resource references** — Verify the chain is correct:
   - IPAM data source → IPAM subnet resource (address reference)
   - IPAM subnet address → VPC CIDR (string construction)
   - VPC CIDR → DNS A record rdata (cidrhost function)
   - DNS zone data source → DNS A record (zone reference)

4. **Validate** — Run `terraform init && terraform validate` in the combined directory.

5. **Review outputs** — Confirm outputs provide everything the workflow will need: VPC ID for display, CIDR for display, FQDN for dig verification, IP value for Route53 API verification.

## Must-Haves

- [ ] IPAM → VPC → DNS resource chain with proper Terraform references (no hardcoded values between phases)
- [ ] `cidrhost(aws_vpc.main.cidr_block, 1)` used for DNS record value (not cidrhost index 0 — that's the network address)
- [ ] VPC CIDR construction replicates exact pattern from `vpc-aws/main.tf` (the `replace(trimspace(...))` pattern)
- [ ] Zone FQDN default is `aws.gh.blox42.rocks.` (trailing dot, matches Route53-synced zone)
- [ ] All AWS resources tagged per D003: `demo = "true"`, `automation = "github-actions"`
- [ ] Variables have proper types, defaults, and validation blocks matching source demos
- [ ] Terraform outputs defined for: `vpc_id`, `vpc_cidr`, `dns_record_fqdn`, `dns_record_value`, `ipam_subnet_address`
- [ ] `terraform init && terraform validate` passes with zero errors

## Verification

- `cd live/demos/combined && terraform init && terraform validate` exits with code 0
- `grep -c 'cidrhost' live/demos/combined/main.tf` returns at least 1
- `grep -c 'output' live/demos/combined/main.tf` returns at least 5 (one per required output)
- `grep 'demo.*true' live/demos/combined/main.tf` shows tag presence on AWS resources

## Inputs

- `live/demos/vpc-aws/main.tf` — Source pattern for IPAM allocation + VPC creation. Key: the CIDR construction uses `replace(trimspace(tolist(...)[0]), "\"", "")` concatenated with `/${var.subnet_size}`.
- `live/demos/vpc-aws/variables.tf` — Variable definitions with validation blocks. `subnet_size` is a number type.
- `live/demos/dns/main.tf` — Source pattern for DNS record creation. Uses `bloxone_dns_auth_zones` data source for zone lookup, then `bloxone_dns_a_record` resource.
- `live/demos/dns/variables.tf` — DNS variables. `zone_fqdn` has trailing dot validation.
- Decision D001: UDDI-native sync only — create DNS record in UDDI, not directly in Route53.
- Decision D003: Tag all resources `demo=true` + `automation=github-actions`.

## Observability Impact

- **Terraform validate** is the primary inspection signal: `cd live/demos/combined && terraform validate` confirms config integrity at any time.
- **Outputs as diagnostic surface**: `terraform output` (after apply) exposes `vpc_id`, `vpc_cidr`, `dns_record_fqdn`, `dns_record_value`, `ipam_subnet_address` — the workflow reads these for narration and verification.
- **Failure visibility**: Terraform plan/apply errors surface as exit code != 0 with HCL-level error messages (resource reference mismatches, provider issues). No custom error handling at this layer — that's the workflow's job (T02).
- **No runtime signals in this task** — this is static configuration. Runtime observability comes from the workflow in T02.

## Expected Output

- `live/demos/combined/main.tf` — Complete Terraform configuration chaining IPAM → VPC → DNS with proper resource references, tags, and outputs
- `live/demos/combined/variables.tf` — Variable definitions with types, defaults, descriptions, and validation blocks
