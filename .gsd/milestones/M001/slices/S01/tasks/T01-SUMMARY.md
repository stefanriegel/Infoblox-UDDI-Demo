---
id: T01
parent: S01
milestone: M001
provides:
  - Terraform root chaining IPAM → VPC → DNS in live/demos/combined/
  - Variable definitions with validation blocks for all workflow inputs
  - Six Terraform outputs for workflow consumption (vpc_id, vpc_cidr, subnet_id, ipam_subnet_address, dns_record_fqdn, dns_record_value)
key_files:
  - live/demos/combined/main.tf
  - live/demos/combined/variables.tf
key_decisions:
  - Replicated exact CIDR construction pattern from vpc-aws (replace/trimspace on results[0]) to avoid provider-specific parsing issues
  - Used cidrhost index 1 (first usable IP) not 0 (network address) for DNS record value
  - Tags use lowercase keys (demo, automation) on AWS resources to match D003 convention from existing demos
patterns_established:
  - Three-phase Terraform config with clear section comments (Phase 1: IPAM, Phase 2: VPC, Phase 3: DNS) for workflow narration alignment
observability_surfaces:
  - terraform validate — confirms config integrity at any time
  - terraform output — exposes vpc_id, vpc_cidr, dns_record_fqdn, dns_record_value, ipam_subnet_address, subnet_id after apply
duration: 10m
verification_result: passed
completed_at: 2026-04-02
blocker_discovered: false
---

# T01: Create Terraform root for combined IPAM+VPC+DNS demo

**Merged vpc-aws and dns demo patterns into a single IPAM → VPC → DNS Terraform root with 6 outputs for workflow consumption.**

## What Happened

Created `live/demos/combined/` with two files:

- **variables.tf**: 8 variables — superset of vpc-aws (bloxone_api_key, vpc_name, subnet_size with 16-28 validation, aws_region, aws_block_id, ipam_space_id) and dns (zone_fqdn with trailing-dot validation defaulting to `aws.gh.blox42.rocks.`, record_name defaulting to `combined-demo`) plus bloxone_host for provider config.

- **main.tf**: Three-phase chain:
  1. **IPAM**: `bloxone_ipam_next_available_subnets` data source → `bloxone_ipam_subnet` resource with demo tags
  2. **VPC**: `aws_vpc` using CIDR from IPAM allocation (exact `replace(trimspace(...))` pattern from vpc-aws) + `aws_internet_gateway`, both tagged per D003
  3. **DNS**: `bloxone_dns_auth_zones` data source for zone lookup → `bloxone_dns_a_record` with `rdata.address = cidrhost(aws_vpc.main.cidr_block, 1)`

Six outputs defined: `vpc_id`, `vpc_cidr`, `subnet_id`, `ipam_subnet_address`, `dns_record_fqdn`, `dns_record_value`.

## Verification

- `terraform init && terraform validate` → `Success! The configuration is valid.` ✅
- `grep -c 'cidrhost' main.tf` → 2 (rdata + output) ✅
- `grep -c 'output' main.tf` → 6 (all required outputs present) ✅
- `grep 'demo.*true' main.tf` → 4 lines (IPAM subnet, VPC, IGW, DNS record all tagged) ✅
- Resource chain verified: IPAM data → IPAM resource → VPC CIDR → DNS A record rdata — all use Terraform references, no hardcoded values ✅

## Slice-Level Verification (partial — T01 of 2)

| Check | Status |
|-------|--------|
| `terraform init && terraform validate` passes | ✅ PASS |
| `combined-demo.yml` valid YAML | ⏳ T02 |
| Cross-reference: workflow vars ↔ variables.tf | ⏳ T02 |
| Cross-reference: step outputs ↔ step IDs | ⏳ T02 |
| Workflow uses only `dev` environment secrets | ⏳ T02 |

## Diagnostics

- Inspect config: `cd live/demos/combined && terraform validate`
- After apply: `cd live/demos/combined && terraform output` shows all six values
- Provider versions: bloxone >= 1.5.0, aws ~> 5.0 (locked in `.terraform.lock.hcl`)

## Deviations

None.

## Known Issues

- `.terraform.lock.hcl` was generated during validation but `.terraform/` directory was cleaned up to avoid committing provider binaries. The lock file should be committed for reproducible builds.

## Files Created/Modified

- `live/demos/combined/main.tf` — Three-phase Terraform config (IPAM → VPC → DNS) with providers, resources, and 6 outputs
- `live/demos/combined/variables.tf` — 8 variable definitions with types, defaults, descriptions, and validation blocks
- `.gsd/milestones/M001/slices/S01/tasks/T01-PLAN.md` — Added Observability Impact section (pre-flight fix)
