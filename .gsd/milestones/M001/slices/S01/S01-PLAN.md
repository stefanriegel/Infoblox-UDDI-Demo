# S01: Combined IPAM+DNS Workflow

**Goal:** A single GitHub Actions workflow that allocates a subnet from UDDI IPAM, provisions a VPC on AWS, creates a DNS A record in UDDI pointing to the VPC's first usable IP, and verifies DNS sync to Route53.

**Demo:** SE triggers `combined-demo.yml` via workflow_dispatch → logs narrate each phase (IPAM → VPC → DNS) with timing → job summary shows 3-stage Mermaid diagram, resource details, and verification results → cleanup destroys all resources on demand.

## Must-Haves

- Terraform root that chains IPAM allocation → VPC creation → DNS A record creation with proper resource references
- `cidrhost(vpc_cidr, 1)` derives the DNS record value from the allocated subnet — realistic "VPC entry point is DNS-resolvable" story
- GitHub Actions workflow with `workflow_dispatch` inputs matching SE expectations (vpc_name, subnet_size, region, action)
- DNS verification: dig against 3 resolvers + Route53 API check (same pattern as `run-demo.yml`)
- Step-by-step log narration with phase timing (IPAM, VPC, DNS, Verification)
- Professional job summary with Mermaid diagram, config table, verification results
- Destroy path that tears down all resources cleanly
- All resources tagged `demo=true` + `automation=github-actions` (D003)
- UDDI-native DNS sync only — no dual-write to Route53 (D001)
- Terraform state cached with unique key `tfstate-combined-*` to avoid collisions (D004)

## Proof Level

- This slice proves: integration (real cloud resources created and verified)
- Real runtime required: yes (GitHub Actions with live credentials)
- Human/UAT required: yes (SE reviews workflow output for demo readiness — deferred to S03)

## Verification

- `cd live/demos/combined && terraform init && terraform validate` passes with zero errors
- `.github/workflows/combined-demo.yml` is valid YAML: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/combined-demo.yml'))"`
- Cross-reference check: every `-var="X=${{ ... }}"` in the workflow has a matching variable in `live/demos/combined/variables.tf`
- Cross-reference check: every `${{ steps.X.outputs.Y }}` in the workflow has a corresponding step ID with that output
- Workflow references only secrets that exist in the `dev` environment: `BLOXONE_API_KEY`, `AWS_BLOCK_ID`, `IPAM_SPACE_ID`, `ROUTE53_HOSTED_ZONE_ID`
- End-to-end: trigger workflow on GitHub Actions (integration verification, requires live credentials)

## Observability / Diagnostics

- Runtime signals: echo-based phase narration in workflow logs (e.g., `echo "🔷 Phase 1: IPAM Allocation"`), `date +%s` timing around each phase
- Inspection surfaces: GitHub Actions job summary (Mermaid diagram + verification table), workflow run logs
- Failure visibility: each phase checks exit code and reports failure context before aborting; Terraform plan output captured in logs; DNS verification shows actual vs expected
- Redaction constraints: `BLOXONE_API_KEY` is a secret; zone names and IPs are safe to display in summaries

## Integration Closure

- Upstream surfaces consumed: `live/demos/vpc-aws/main.tf` (IPAM+VPC pattern), `live/demos/dns/main.tf` (DNS record pattern), `.github/workflows/run-demo.yml` (verification + summary pattern)
- New wiring introduced in this slice: `live/demos/combined/` Terraform root + `.github/workflows/combined-demo.yml` workflow
- What remains before the milestone is truly usable end-to-end: S02 polishes presentation consistency across all workflows; S03 adds SE-friendly input defaults, cleanup integration, and final QA

## Tasks

- [ ] **T01: Create Terraform root for combined IPAM+VPC+DNS demo** `est:45m`
  - Why: The Terraform configuration is the foundation — the workflow can't be written until outputs are defined. This merges the proven VPC-AWS and DNS patterns into a single root that chains IPAM allocation → VPC → DNS A record.
  - Files: `live/demos/combined/main.tf`, `live/demos/combined/variables.tf`
  - Do: Create `main.tf` merging providers (bloxone + aws + bloxone DNS), IPAM next_available_subnets → subnet reservation → VPC + IGW → DNS zone lookup → A record using `cidrhost(aws_vpc.main.cidr_block, 1)`. Create `variables.tf` with superset of vpc-aws + dns variables. Tag all resources per D003. Add Terraform outputs for workflow consumption: `vpc_id`, `vpc_cidr`, `subnet_id`, `dns_record_fqdn`, `dns_record_value`, `ipam_subnet_address`.
  - Verify: `cd live/demos/combined && terraform init && terraform validate` exits 0
  - Done when: Terraform validates cleanly and outputs cover everything the workflow will need (VPC CIDR, DNS FQDN, record IP)

- [ ] **T02: Create GitHub Actions workflow with narration, verification, and job summary** `est:1h`
  - Why: The workflow is the SE-facing artifact — it wires the Terraform root into a triggerable demo with narrated logs, DNS verification, and a professional summary. Also performs coherence verification against T01's variables/outputs.
  - Files: `.github/workflows/combined-demo.yml`
  - Do: Create workflow with `workflow_dispatch` inputs (vpc_name, subnet_size as choice, action as choice deploy/destroy). Structure: checkout → setup terraform 1.6.6 → cache restore (key: `tfstate-combined-${{ inputs.vpc_name }}`) → init → narrated plan/apply with phase timing (IPAM, VPC, DNS) → extract Terraform outputs → DNS verification (sleep 15 + dig against 8.8.8.8, 1.1.1.1, 9.9.9.9 + Route53 API via `aws route53 list-resource-record-sets`) → generate job summary with Mermaid 3-stage diagram, config table, verification results, value proposition footer → destroy path. Use `dev` environment for secrets. Cross-reference all `-var` flags against `variables.tf`, all step output references against step IDs. Follow `run-demo.yml` patterns for summary generation and verification. Skill note: load `github-workflows` skill for workflow syntax reference.
  - Verify: YAML parses cleanly; every workflow variable reference maps to a Terraform variable; every step output reference has a source step; workflow references only known secrets from `dev` environment
  - Done when: Workflow file is syntactically valid, all cross-references are correct, and the file is ready for a live GitHub Actions run

## Files Likely Touched

- `live/demos/combined/main.tf`
- `live/demos/combined/variables.tf`
- `.github/workflows/combined-demo.yml`
