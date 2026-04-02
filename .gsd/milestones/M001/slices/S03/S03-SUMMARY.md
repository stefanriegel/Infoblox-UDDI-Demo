---
id: S03
parent: M001
milestone: M001
provides:
  - SE-friendly workflow_dispatch inputs with examples and sensible defaults across all 4 workflows
  - Cleanup-discoverable tags (uppercase Demo/ManagedBy) on combined demo VPC and IGW
  - UDDI branding badge in combined-demo.yml (completing 4/4 badge coverage)
  - Cross-suite verification script (scripts/verify-s03.sh) with 15 consistency checks
  - Zero-config VPC demo experience (deploy_aws defaults to true)
requires:
  - slice: S01
    provides: combined-demo.yml workflow and live/demos/combined/ Terraform configs
  - slice: S02
    provides: Presentation patterns (badge, HEADER/FOOTER heredoc, Mermaid palette, narration boxes) established across DNS, VPC, and cleanup workflows
affects: []
key_files:
  - live/demos/combined/main.tf
  - .github/workflows/combined-demo.yml
  - .github/workflows/run-demo.yml
  - .github/workflows/vpc-deployment.yml
  - .github/workflows/cleanup.yml
  - scripts/verify-s03.sh
key_decisions:
  - Kept lowercase `demo = "true"` alongside uppercase `Demo = "true"` for backward compatibility (extends D003)
  - deploy_aws defaults to true for zero-config SE experience (per D002)
patterns_established:
  - All AWS resources in demo Terraform must have `Demo = "true"` and `ManagedBy = "terraform"` tags (uppercase) for cleanup discovery
  - Workflow input descriptions include concrete examples and CIDR explanations for SE clarity
  - Cross-suite consistency verified via scripts/verify-s03.sh (15 checks)
observability_surfaces:
  - scripts/verify-s03.sh — 15-check cross-suite validation (YAML, badges, tags, terraform, narration, SE inputs)
  - Cleanup workflow discovery logs — combined demo VPCs appear when tags are correct
drill_down_paths:
  - .gsd/milestones/M001/slices/S03/tasks/T01-SUMMARY.md
  - .gsd/milestones/M001/slices/S03/tasks/T02-SUMMARY.md
duration: 25m
verification_result: passed
completed_at: 2026-04-02
---

# S03: SE Experience & Final Integration

**All 4 demo workflows polished with SE-friendly inputs, consistent UDDI branding, cleanup-discoverable tags, and a 15-check cross-suite verification script — completing the demo suite for customer presentation.**

## What Happened

This slice was the final-assembly pass that ensured the full demo suite is consistent and SE-ready. Two tasks:

**T01** fixed the combined demo's infrastructure tags and branding gap. The VPC and IGW in `live/demos/combined/main.tf` had lowercase `demo = "true"` which the cleanup workflow's tag filter (`tag:Demo,Values=true`) wouldn't match. Added uppercase `Demo = "true"` and `ManagedBy = "terraform"` tags to both resources, keeping the lowercase originals for backward compatibility. Also added the UDDI badge to `combined-demo.yml`'s job summary — the only workflow missing it after S02's polish pass.

**T02** polished all 4 workflows' `workflow_dispatch` inputs for SE clarity. Key changes: expanded `record_value` in the DNS workflow with concrete examples per record type, changed VPC `deploy_aws` default from `false` to `true` for zero-config demos, added "(recommended for first demo)" guidance to provider toggles, and improved `subnet_size` descriptions with CIDR explanations. Created `scripts/verify-s03.sh` — a comprehensive verification script that validates YAML parsing, UDDI badge presence, combined demo tags, Terraform validation, narration presence, and SE-friendly input assertions (15 checks total).

## Verification

- `bash scripts/verify-s03.sh` → **15 passed, 0 failed**
- Badge present in all 4 workflows (grep confirms: cleanup=2, combined=1, run-demo=1, vpc=1)
- `ManagedBy` tag count in combined/main.tf = 2 (VPC + IGW)
- `Demo = "true"` tag count in combined/main.tf = 2 (VPC + IGW)
- All 4 YAML files parse successfully via Python yaml.safe_load
- `terraform validate` passes for live/demos/combined/
- VPC workflow deploy_aws default confirmed as `true`
- DNS record_value description includes IP address examples

## Requirements Advanced

- R005 (Production-grade feel) — Cleanup now discovers combined demo resources via correct tags; cross-suite verification script ensures consistency isn't accidentally broken
- R010 (SE-friendly inputs) — All 4 workflows have expanded descriptions with examples, sensible defaults (deploy_aws=true), and logical ordering

## Requirements Validated

- R001 — Static verification complete across all artifacts (Terraform validates, YAML parses, tags match cleanup filters, badge present). Live run still required for full validation.
- R004 — All 4 workflows now have consistent UDDI branding badge, verified by grep count = 4/4
- R010 — Input descriptions polished with examples, defaults optimized for zero-config demo. Verified by verification script assertions.

## New Requirements Surfaced

- none

## Requirements Invalidated or Re-scoped

- none

## Deviations

- T01: Badge URL in plan omitted `?style=for-the-badge` suffix but all other workflows used it — matched the real pattern instead of the plan's URL.
- T01: No `aws_subnet` resource exists in combined demo (only `bloxone_ipam_subnet`), so planned subnet tagging was N/A.
- T02: YAML `on` key parses as Python boolean `True` — verification script uses `d[True]` instead of `d['on']`.

## Known Limitations

- All verification is static — no live GitHub Actions runs have been performed. Tag correctness for cleanup discovery is verified by grep but not by actual AWS tag filter API calls.
- Visual rendering of badges, Mermaid diagrams, and job summaries requires a real GitHub Actions run to confirm.
- Combined workflow has not been run end-to-end with real cloud resources — Terraform validates but runtime behavior is unproven.

## Follow-ups

- Live GitHub Actions run of all 4 workflows to visually confirm rendering and runtime behavior
- SE walkthrough / UAT of the complete demo suite
- R012 (README/docs update) remains deferred

## Files Created/Modified

- `live/demos/combined/main.tf` — Added uppercase `Demo` and `ManagedBy` tags to VPC and IGW
- `.github/workflows/combined-demo.yml` — Added UDDI badge, expanded subnet_size description
- `.github/workflows/run-demo.yml` — Expanded record_value, record_name, ttl, action input descriptions
- `.github/workflows/vpc-deployment.yml` — deploy_aws defaults to true, all input descriptions improved
- `.github/workflows/cleanup.yml` — Improved confirm input description
- `scripts/verify-s03.sh` — New 15-check cross-suite verification script

## Forward Intelligence

### What the next slice should know
- The full demo suite (4 workflows) is statically verified and presentation-consistent. The remaining gap is live runtime validation — no workflow has been run on GitHub Actions since these changes.
- `scripts/verify-s03.sh` is the authoritative consistency check. Run it after any workflow YAML or Terraform change.

### What's fragile
- Tag case sensitivity — cleanup filters on uppercase `Demo`/`ManagedBy` but Terraform tags are just string keys. A future edit could accidentally revert to lowercase and break cleanup discovery silently.
- YAML `on` key parsing as Python boolean `True` — any Python-based YAML tooling must use `d[True]` not `d['on']`.

### Authoritative diagnostics
- `bash scripts/verify-s03.sh` — the single command to verify cross-suite consistency (15 checks)
- `grep -c 'ManagedBy' live/demos/combined/main.tf` — quick check that cleanup tags are present (expect ≥2)
- Cleanup workflow discovery logs — after a combined demo deploy, VPC should appear in cleanup's discovery output

### What assumptions changed
- Original plan assumed `aws_subnet` resource existed in combined demo — it doesn't (only `bloxone_ipam_subnet`), so only VPC and IGW needed tags.
