---
id: S01
parent: M001
milestone: M001
provides:
  - Complete combined IPAM+VPC+DNS Terraform root in live/demos/combined/
  - GitHub Actions workflow (combined-demo.yml) with deploy/destroy, narrated phases, DNS verification, and Mermaid job summary
  - 6 Terraform outputs for workflow consumption (vpc_id, vpc_cidr, subnet_id, ipam_subnet_address, dns_record_fqdn, dns_record_value)
requires: []
affects:
  - S03
key_files:
  - live/demos/combined/main.tf
  - live/demos/combined/variables.tf
  - .github/workflows/combined-demo.yml
key_decisions:
  - Atomic terraform apply with post-hoc phase narration (Terraform can't apply phases separately)
  - Deploy and destroy as separate jobs (not conditional blocks) for cleaner logs
  - Variables with defaults (aws_region, record_name, zone_fqdn) omitted from -var flags — Terraform uses defaults
  - Literal zone name in summary to avoid GitHub secret masking on interpolated values
patterns_established:
  - Three-phase Terraform config with section comments (Phase 1: IPAM, Phase 2: VPC, Phase 3: DNS) aligning with workflow narration
  - DNS verification pattern: 15s sleep → dig 3 resolvers (8.8.8.8, 1.1.1.1, 9.9.9.9) → Route53 API check → verification table with ✅/❌
  - Job summary structure: Mermaid 3-stage diagram → config table → results table → verification table → value proposition footer
  - Deploy/destroy job split with shared cache key pattern: tfstate-combined-${{ inputs.vpc_name }}
observability_surfaces:
  - GitHub Actions job summary with Mermaid diagram and verification table
  - Echo-based phase narration in workflow logs
  - Per-resolver DNS verification with expected vs actual values
  - terraform output for post-apply inspection of all 6 values
drill_down_paths:
  - .gsd/milestones/M001/slices/S01/tasks/T01-SUMMARY.md
  - .gsd/milestones/M001/slices/S01/tasks/T02-SUMMARY.md
duration: 35m
verification_result: passed
completed_at: 2026-04-02
---

# S01: Combined IPAM+DNS Workflow

**Single GitHub Actions workflow chains IPAM allocation → VPC provisioning → DNS A record creation with narrated phases, DNS verification against 3 resolvers + Route53 API, and Mermaid job summary — all from one `workflow_dispatch` trigger.**

## What Happened

T01 created the Terraform root (`live/demos/combined/`) by merging the proven `vpc-aws` and `dns` demo patterns into a three-phase configuration. Phase 1 uses `bloxone_ipam_next_available_subnets` to allocate a subnet, Phase 2 creates an AWS VPC + IGW using the IPAM-allocated CIDR (exact `replace(trimspace(...))` pattern from vpc-aws), and Phase 3 looks up the UDDI DNS zone and creates an A record pointing to `cidrhost(vpc_cidr, 1)` — the first usable IP. Eight variables cover the superset of both upstream demos, with validation blocks on subnet_size (16-28) and zone_fqdn (trailing dot). Six outputs expose everything the workflow needs.

T02 built the workflow (`combined-demo.yml`) with two jobs: `deploy` and `destroy`, conditioned on the `action` input. The deploy job narrates three phases with timing, extracts all 6 Terraform outputs into step outputs, runs DNS verification (15s wait → dig against 3 public resolvers → Route53 API query), and generates a professional job summary with a 3-stage Mermaid diagram, configuration table, resource results, verification results with ✅/❌, and a UDDI value proposition footer. The destroy job restores cached state and tears down all resources. Only 3 workflow inputs (vpc_name, subnet_size, action) — everything else uses sensible defaults or secrets.

## Verification

| Check | Status |
|-------|--------|
| `terraform init && terraform validate` passes | ✅ PASS |
| `combined-demo.yml` valid YAML | ✅ PASS |
| All 6 `-var` flags map to `variables.tf` variables | ✅ PASS |
| 3 variables with defaults correctly omitted from `-var` flags | ✅ PASS |
| All `steps.X.outputs.Y` refs resolve to defined step IDs | ✅ PASS |
| Workflow uses only `dev` environment secrets | ✅ PASS |
| All resources tagged `demo=true` + `automation=github-actions` | ✅ PASS |
| End-to-end GitHub Actions run | ⏳ Deferred — requires live credentials |

## Requirements Advanced

- R001 — Combined workflow fully built: IPAM → VPC → DNS → verify in one trigger. Awaits live run for validation.
- R002 — Combined workflow includes phase narration with banners and timing. S02 owns full narration polish across all workflows.
- R005 — DNS verification against 3 resolvers + Route53 API, resource tagging, clean destroy path. S03 owns final QA.
- R008 — Apply duration captured and reported in job summary. S02 owns timing polish across all workflows.

## Requirements Validated

- None — R001 requires a live GitHub Actions run to validate. Static verification is complete.

## New Requirements Surfaced

- None

## Requirements Invalidated or Re-scoped

- None

## Deviations

None. Both tasks executed to plan.

## Known Limitations

- End-to-end integration testing requires live GitHub Actions run with real cloud credentials (deferred to manual trigger)
- Phase timing is aggregate (total apply duration) not per-phase — Terraform applies atomically, individual phase timing would require parsing apply output
- `.terraform.lock.hcl` generated during validation should be committed for reproducible builds
- Zone name is hardcoded as literal in summary to work around GitHub secret masking — changing the zone requires updating the workflow summary template

## Follow-ups

- Trigger live GitHub Actions run to validate R001 end-to-end
- S03: Apply SE-friendly input polish (descriptions, defaults) to combined workflow inputs
- S03: Extend cleanup workflow to discover and destroy combined demo resources by tag
- Commit `.terraform.lock.hcl` for reproducible provider versions

## Files Created/Modified

- `live/demos/combined/main.tf` — Three-phase Terraform config (IPAM → VPC → DNS) with 3 providers, 5 resources, 6 outputs
- `live/demos/combined/variables.tf` — 8 variable definitions with types, defaults, descriptions, and validation blocks
- `.github/workflows/combined-demo.yml` — Complete workflow with deploy + destroy jobs, narration, DNS verification, Mermaid summary

## Forward Intelligence

### What the next slice should know
- The combined workflow follows the same verification pattern as `run-demo.yml` (dig + Route53 API) — S02 should use this as the reference when standardizing verification across all workflows
- Variables with defaults are intentionally omitted from `-var` flags. If S03 changes defaults, no workflow change is needed.
- The 3 workflow inputs (vpc_name, subnet_size, action) are the SE-facing surface. S03 should focus input polish here.

### What's fragile
- Literal zone name `aws.gh.blox42.rocks` in the job summary Mermaid diagram and text — if the zone changes, the summary will be wrong even though Terraform uses the variable default correctly
- The `replace(trimspace(results[0]))` CIDR parsing pattern from the IPAM provider — if the provider changes its output format, both vpc-aws and combined demos break simultaneously

### Authoritative diagnostics
- `cd live/demos/combined && terraform validate` — confirms Terraform config integrity at any time
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/combined-demo.yml'))"` — confirms workflow YAML validity
- After a live run: GitHub Actions job summary shows Mermaid diagram + verification table with ✅/❌ per resolver

### What assumptions changed
- No assumptions changed. Both upstream patterns (vpc-aws CIDR parsing, dns verification) worked as expected when merged.
