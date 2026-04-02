---
id: T01
parent: S03
milestone: M001
provides:
  - Cleanup-discoverable tags on combined demo VPC and IGW resources
  - UDDI branding badge in combined-demo.yml job summary
key_files:
  - live/demos/combined/main.tf
  - .github/workflows/combined-demo.yml
key_decisions:
  - Kept lowercase `demo = "true"` alongside uppercase `Demo = "true"` for backward compatibility
patterns_established:
  - All AWS resources in demo Terraform configs must have `Demo = "true"` and `ManagedBy = "terraform"` tags (uppercase) for cleanup workflow discovery
observability_surfaces:
  - Cleanup workflow discovery logs show combined demo VPCs when tags are correct; 0 VPCs means tag mismatch
duration: 10m
verification_result: passed
completed_at: 2026-04-02
blocker_discovered: false
---

# T01: Fix combined demo tags and add UDDI badge for cleanup discovery and presentation consistency

**Added uppercase `Demo`/`ManagedBy` tags to VPC+IGW for cleanup discovery, and UDDI badge to combined-demo.yml summary.**

## What Happened

1. Added `Demo = "true"` and `ManagedBy = "terraform"` tags to both `aws_vpc.main` and `aws_internet_gateway.main` in `live/demos/combined/main.tf`. Kept existing lowercase `demo = "true"` for backward compatibility.
2. No `aws_subnet` resource exists in the combined demo (only `bloxone_ipam_subnet` which doesn't need AWS cleanup tags) — step 3 from plan was N/A.
3. Added UDDI badge to `combined-demo.yml` job summary using the exact `HEADER` heredoc pattern from other workflows: `![UDDI](https://img.shields.io/badge/Infoblox-Universal_DDI-0066cc?style=for-the-badge)`. Note: the plan referenced `?style=for-the-badge` was missing from the plan's badge URL but present in all other workflows — matched the actual pattern.
4. Validated Terraform (`terraform validate` passes) and YAML (Python yaml.safe_load passes).

## Verification

- `grep -c 'ManagedBy' live/demos/combined/main.tf` → **2** ✅
- `grep 'Demo.*=.*"true"' live/demos/combined/main.tf` → 2 matches (VPC + IGW) ✅
- `grep -c 'Infoblox-Universal_DDI-0066cc' .github/workflows/combined-demo.yml` → **1** ✅
- All 4 workflow YAMLs have badge: cleanup(2), combined(1), run-demo(1), vpc(1) ✅
- All 4 YAMLs parse as valid YAML ✅
- `terraform validate` passes for `live/demos/combined/` ✅

### Slice-level verification status (partial — T02 pending)
- ✅ Badge count across all 4 workflows ≥1 each
- ✅ ManagedBy count ≥2 in main.tf
- ✅ Demo tag count ≥2 in main.tf
- ✅ All YAML files valid
- ✅ Terraform validate passes
- ⏳ `scripts/verify-s03.sh` — not yet created (T02 deliverable)

## Diagnostics

- **Tag correctness:** `grep -c 'ManagedBy' live/demos/combined/main.tf` should return ≥2. If cleanup workflow can't find combined demo VPCs, check tag case (`Demo` vs `demo`).
- **Badge presence:** `grep 'Infoblox-Universal_DDI' .github/workflows/combined-demo.yml` confirms badge in source. Visual confirmation requires running the workflow in GitHub Actions.

## Deviations

- Badge URL in plan was `https://img.shields.io/badge/Infoblox-Universal_DDI-0066cc` but actual pattern across all workflows uses `?style=for-the-badge` suffix. Matched the real pattern.
- No `aws_subnet` resource exists in combined demo, so step 3 (add tags to subnet) was skipped as N/A.

## Known Issues

None.

## Files Created/Modified

- `live/demos/combined/main.tf` — Added `Demo = "true"` and `ManagedBy = "terraform"` tags to VPC and IGW resources
- `.github/workflows/combined-demo.yml` — Added UDDI branding badge to job summary HEADER block
- `.gsd/milestones/M001/slices/S03/S03-PLAN.md` — Marked T01 done, added Observability/Diagnostics section
