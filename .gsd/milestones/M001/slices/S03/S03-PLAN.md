# S03: SE Experience & Final Integration

**Goal:** All workflow inputs are SE-friendly with clear labels and defaults, cleanup handles combined demo resources, and the full demo suite is production-grade.
**Demo:** An SE triggers any of the 4 workflows with zero prep, the inputs are self-explanatory, the output tells the UDDI story, and cleanup discovers and removes all demo resources including combined workflow VPCs.

## Must-Haves

- Combined demo VPC/IGW tagged with `Demo = "true"` and `ManagedBy = "terraform"` (uppercase, matching cleanup filter)
- UDDI branding badge present in all 4 workflow summaries (combined-demo.yml currently missing it)
- All workflow_dispatch inputs have clear descriptions, sensible defaults, and logical ordering
- Cross-workflow consistency verified: badge count = 4, all YAML valid, all Terraform valid

## Proof Level

- This slice proves: final-assembly
- Real runtime required: no (live GitHub Actions run deferred — static verification covers all changes)
- Human/UAT required: yes (SE should trigger each workflow once to confirm full experience)

## Verification

- `grep -c 'Infoblox-Universal_DDI-0066cc' .github/workflows/*.yml` — all 4 files return ≥1
- `grep -c 'ManagedBy' live/demos/combined/main.tf` returns ≥2 (VPC + IGW)
- `grep -c 'Demo.*=.*"true"' live/demos/combined/main.tf` returns ≥2 (VPC + IGW)
- `for f in .github/workflows/*.yml; do python3 -c "import yaml; yaml.safe_load(open('$f'))"; done` — all pass
- `cd live/demos/combined && terraform init -backend=false && terraform validate` — passes
- `bash scripts/verify-s03.sh` — runs all checks above plus input description coverage
- **Failure-path check:** Run cleanup workflow with `dry_run: true` after deploying combined demo — verify VPC appears in cleanup discovery list (tag match). If VPC is missing from discovery output, tags are wrong.

## Observability / Diagnostics

- **Cleanup discovery:** The cleanup workflow logs all resources it discovers via tag filters (`tag:Demo,Values=true` + `tag:ManagedBy,Values=terraform`). After a combined demo deploy, the VPC and IGW should appear in cleanup's discovery output. If they don't, the tags in `main.tf` are incorrect.
- **Badge rendering:** Job summaries are visible in the GitHub Actions run UI. Each workflow's summary tab should show the UDDI badge at the top. Visual inspection confirms rendering; `grep` confirms presence in source.
- **Terraform validate:** Static validation catches tag syntax errors (e.g., duplicate keys, invalid HCL). No runtime signals needed — these are infrastructure tags, not application code.
- **Failure visibility:** If cleanup can't find combined demo resources, the cleanup workflow's summary will show 0 VPCs discovered. This is the primary failure signal for incorrect tags.

## Integration Closure

- Upstream surfaces consumed: `combined-demo.yml` from S01, presentation patterns (badge, HEADER/EOF/FOOTER heredoc, Mermaid palette) from S02, cleanup tag filter from existing `cleanup.yml`
- New wiring introduced in this slice: none — this slice aligns existing artifacts, no new runtime paths
- What remains before the milestone is truly usable end-to-end: Live GitHub Actions runs of all 4 workflows to visually confirm rendering

## Tasks

- [x] **T01: Fix combined demo tags and add UDDI badge for cleanup discovery and presentation consistency** `est:25m`
  - Why: Combined demo VPCs use lowercase `demo` tag and lack `ManagedBy = "terraform"` — cleanup workflow can't discover them (filters on `tag:Demo,Values=true` + `tag:ManagedBy,Values=terraform`). Combined workflow also missing the UDDI branding badge that S02 added to the other 3 workflows.
  - Files: `live/demos/combined/main.tf`, `.github/workflows/combined-demo.yml`
  - Do: (1) In `main.tf`, add `Demo = "true"` and `ManagedBy = "terraform"` tags to VPC and IGW resources. Keep existing lowercase `demo` for belt-and-suspenders. (2) In `combined-demo.yml`, add the UDDI badge `![Infoblox](https://img.shields.io/badge/Infoblox-Universal_DDI-0066cc)` to the job summary, matching the pattern from the other 3 workflows. (3) Verify Terraform validates and YAML parses.
  - Verify: `grep -c 'ManagedBy' live/demos/combined/main.tf` returns ≥2; `grep -c 'Infoblox-Universal_DDI-0066cc' .github/workflows/combined-demo.yml` returns ≥1; `terraform validate` passes; YAML parses.
  - Done when: Cleanup filter will match combined demo VPCs, and badge count across all 4 workflows is ≥4.

- [ ] **T02: Polish workflow inputs for SE experience and add cross-suite verification** `est:30m`
  - Why: R010 requires SE-friendly inputs. Some workflows have terse descriptions, all-false defaults (VPC cloud booleans), or missing examples. A verification script ensures cross-workflow consistency is maintained.
  - Files: `.github/workflows/combined-demo.yml`, `.github/workflows/run-demo.yml`, `.github/workflows/vpc-deployment.yml`, `.github/workflows/cleanup.yml`, `scripts/verify-s03.sh`
  - Do: (1) Polish input descriptions across all 4 workflows — add examples where helpful, clarify terse descriptions (e.g., DNS `record_value`), ensure defaults make sense for zero-config demo. (2) Consider defaulting `deploy_aws: true` in VPC workflow so SE doesn't need to toggle anything. (3) Write `scripts/verify-s03.sh` that checks: all 4 YAMLs valid, all Terraform roots validate, badge count = 4, tag consistency, narration present in all workflows. (4) Run the script and fix any issues.
  - Verify: `bash scripts/verify-s03.sh` passes all checks.
  - Done when: All workflow inputs are self-documenting for an SE, verification script passes, and the full demo suite is consistent.

## Files Likely Touched

- `live/demos/combined/main.tf`
- `.github/workflows/combined-demo.yml`
- `.github/workflows/run-demo.yml`
- `.github/workflows/vpc-deployment.yml`
- `.github/workflows/cleanup.yml`
- `scripts/verify-s03.sh`
