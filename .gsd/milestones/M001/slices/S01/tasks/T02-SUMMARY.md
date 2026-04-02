---
id: T02
parent: S01
milestone: M001
provides:
  - GitHub Actions workflow combining IPAM+VPC+DNS with narrated deploy, DNS verification, and destroy paths
key_files:
  - .github/workflows/combined-demo.yml
key_decisions:
  - Used atomic terraform apply with post-hoc phase narration (Terraform can't apply phases separately)
  - Variables with defaults (aws_region, record_name, zone_fqdn) omitted from -var flags — Terraform uses defaults
  - Literal zone name "aws.gh.blox42.rocks" in summary to avoid GitHub secret masking
patterns_established:
  - Deploy/destroy split into separate jobs (not if-blocks within one job) for cleaner logs
  - Phase narration: banner before plan, output extraction after apply, per-resource reporting
  - DNS verification: 15s sleep → dig 3 resolvers → Route53 API → verification summary with ✅/❌
observability_surfaces:
  - GitHub Actions job summary (Mermaid diagram + verification table)
  - Echo-based phase narration in workflow logs
  - Per-resolver DNS verification with expected vs actual
duration: 25m
verification_result: passed
completed_at: 2025-04-02
blocker_discovered: false
---

# T02: Create GitHub Actions workflow with narration, verification, and job summary

**Built complete `combined-demo.yml` workflow with 3-phase narration, DNS verification against 3 resolvers + Route53 API, Mermaid job summary, and destroy path.**

## What Happened

Created `.github/workflows/combined-demo.yml` with two jobs: `deploy` and `destroy`, conditioned on the `action` input. The deploy job follows this structure:

1. **Setup** — checkout, terraform 1.6.6, cache restore with key `tfstate-combined-${{ inputs.vpc_name }}`
2. **Narrated Plan** — banner showing all 3 phases, then `terraform plan` with 6 `-var` flags
3. **Timed Apply** — captures `date +%s` start/end for duration reporting
4. **Output Extraction** — all 6 terraform outputs parsed into step outputs for downstream use
5. **DNS Verification** — 15s sync wait, dig against 8.8.8.8/1.1.1.1/9.9.9.9, Route53 API check
6. **Job Summary** — Mermaid 3-stage diagram, config table, results table, verification table with ✅/❌, value proposition footer

The destroy job restores cache, runs `terraform destroy` with all required variables, and saves state.

## Verification

- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/combined-demo.yml'))"` → exits 0 ✅
- Workflow `-var` flags (6): `bloxone_host`, `bloxone_api_key`, `vpc_name`, `subnet_size`, `aws_block_id`, `ipam_space_id` — all exist in `variables.tf` ✅
- Variables with defaults not passed: `aws_region`, `record_name`, `zone_fqdn` — Terraform uses defaults ✅
- Step output cross-reference: all `steps.X.outputs.Y` map to defined step IDs (`apply`, `dns_verify`, `outputs`) ✅
- Input count: exactly 3 (`vpc_name`, `subnet_size`, `action`) ✅
- Secrets used: `BLOXONE_API_KEY`, `AWS_BLOCK_ID`, `IPAM_SPACE_ID`, `ROUTE53_HOSTED_ZONE_ID`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` — all via `dev` environment ✅
- Terraform validate on combined root: `Success! The configuration is valid.` ✅

### Slice-level verification status (T02 = final task in S01):

- [x] `terraform init && terraform validate` passes
- [x] YAML parses cleanly
- [x] Cross-reference: all `-var` flags map to variables.tf
- [x] Cross-reference: all step output refs resolve
- [x] Workflow uses only known secrets from `dev` environment
- [ ] End-to-end trigger on GitHub Actions (deferred — requires live credentials)

## Diagnostics

- Trigger: `gh workflow run combined-demo.yml -f vpc_name=test -f subnet_size=24 -f action=deploy`
- Monitor: `gh run list --workflow=combined-demo.yml` then `gh run view <id> --log`
- Job summary visible in GitHub Actions UI after run completes

## Deviations

None.

## Known Issues

None.

## Files Created/Modified

- `.github/workflows/combined-demo.yml` — Complete workflow with deploy + destroy jobs
- `.gsd/milestones/M001/slices/S01/tasks/T02-PLAN.md` — Added missing Observability Impact section
