---
id: T02
parent: S03
milestone: M001
provides:
  - SE-friendly workflow_dispatch input descriptions with examples across all 4 workflows
  - Zero-config VPC demo experience (deploy_aws defaults to true)
  - Cross-suite verification script (scripts/verify-s03.sh) validating 15 consistency checks
key_files:
  - .github/workflows/run-demo.yml
  - .github/workflows/vpc-deployment.yml
  - .github/workflows/combined-demo.yml
  - .github/workflows/cleanup.yml
  - scripts/verify-s03.sh
key_decisions:
  - deploy_aws defaults to true per D002 (AWS is primary demo target)
  - Kept cleanup confirm input largely unchanged — safety gate is already clear
patterns_established:
  - Workflow input descriptions should include concrete examples (e.g., "10.0.1.1") and CIDR explanations
  - YAML `on` key parses as Python boolean True — use d[True] not d['on'] in verification scripts
observability_surfaces:
  - scripts/verify-s03.sh — 15-check cross-suite validation (YAML, badges, tags, terraform, narration, SE inputs)
duration: 15m
verification_result: passed
completed_at: 2025-04-02
blocker_discovered: false
---

# T02: Polish workflow inputs for SE experience and add cross-suite verification

**Expanded all 4 workflow input descriptions for SE clarity, defaulted VPC deploy_aws to true, and created 15-check cross-suite verification script**

## What Happened

Polished workflow_dispatch inputs across all 4 workflows:

1. **combined-demo.yml**: Expanded `subnet_size` description with CIDR explanation ("smaller number = larger subnet").
2. **run-demo.yml**: Expanded `record_value` with concrete examples per record type, improved `record_name` with zone suffix note, clarified `ttl` and `action` descriptions.
3. **vpc-deployment.yml**: Changed `deploy_aws` default from `false` to `true` for zero-config demo. Added "(recommended for first demo)" to AWS, "(adds multi-cloud story)" to Azure/GCP. Expanded `network_name`, `subnet_size`, `vpc_count`, region descriptions.
4. **cleanup.yml**: Improved `confirm` description to "Safety gate — type 'destroy' to confirm cleanup of all demo resources".
5. **scripts/verify-s03.sh**: Created comprehensive verification script with 15 checks across YAML parsing, UDDI branding, combined demo tags, Terraform validation, narration presence, and SE-friendly input assertions.

## Verification

- `bash scripts/verify-s03.sh` → 15 passed, 0 failed
- `grep -A5 'deploy_aws:' .github/workflows/vpc-deployment.yml` confirms `default: true`
- `grep -A2 'record_value' .github/workflows/run-demo.yml` shows expanded description with examples
- All 4 YAML files parse successfully
- Slice-level checks: badge count 4/4, ManagedBy count 2, Demo tag count 2, Terraform validates

## Diagnostics

- Run `bash scripts/verify-s03.sh` to verify cross-suite consistency at any time
- If VPC workflow preflight fails with "No cloud provider selected" after a revert, check that `deploy_aws` default is `true`
- GitHub Actions workflow dispatch UI shows input descriptions — visual inspection confirms SE experience

## Deviations

- YAML `on` key parses as Python boolean `True` — had to use `d[True]` instead of `d['on']` in the verification script's deploy_aws default check
- Bash `((PASS++))` fails under `set -e` when PASS=0 (returns exit code 1) — used `PASS=$((PASS + 1))` instead

## Known Issues

None

## Files Created/Modified

- `.github/workflows/combined-demo.yml` — Expanded subnet_size description with CIDR explanation
- `.github/workflows/run-demo.yml` — Expanded record_value, record_name, ttl, action descriptions with examples
- `.github/workflows/vpc-deployment.yml` — deploy_aws defaults to true, all input descriptions improved
- `.github/workflows/cleanup.yml` — Improved confirm input description
- `scripts/verify-s03.sh` — New cross-suite verification script (15 checks)
- `.gsd/milestones/M001/slices/S03/tasks/T02-PLAN.md` — Added Observability Impact section
