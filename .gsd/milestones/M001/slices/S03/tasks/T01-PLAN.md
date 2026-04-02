---
estimated_steps: 5
estimated_files: 2
---

# T01: Fix combined demo tags and add UDDI badge for cleanup discovery and presentation consistency

**Slice:** S03 — SE Experience & Final Integration
**Milestone:** M001

## Description

The combined demo's VPC and IGW resources use lowercase `demo = "true"` but the cleanup workflow filters on `tag:Demo,Values=true` (uppercase D) and `tag:ManagedBy,Values=terraform`. This means combined demo VPCs survive cleanup — a real bug that leaves orphaned cloud resources. Additionally, `combined-demo.yml` is the only workflow missing the UDDI branding badge that S02 established across the other 3 workflows.

This task fixes both: correct the tags for cleanup discovery, and add the badge for presentation consistency.

**Relevant skill:** `github-workflows` (for workflow YAML editing)

## Steps

1. Open `live/demos/combined/main.tf` and locate the `aws_vpc` resource tags block (around line 60-70). Add `Demo = "true"` and `ManagedBy = "terraform"` tags. Keep the existing lowercase `demo = "true"` for backward compatibility. The tags block should look like:
   ```hcl
   tags = {
     Name       = var.vpc_name
     demo       = "true"
     Demo       = "true"
     ManagedBy  = "terraform"
     automation = "github-actions"
   }
   ```

2. In the same file, locate the `aws_internet_gateway` resource tags block and add the same `Demo = "true"` and `ManagedBy = "terraform"` tags. Keep existing lowercase `demo`.

3. Also check the `aws_subnet` resource tags — add `Demo = "true"` and `ManagedBy = "terraform"` there too if missing, for consistency.

4. Open `.github/workflows/combined-demo.yml` and find the job summary section (the heredoc that writes to `$GITHUB_STEP_SUMMARY`). Add the UDDI badge as the first line of the summary, matching the exact format from the other workflows:
   ```
   ![Infoblox](https://img.shields.io/badge/Infoblox-Universal_DDI-0066cc)
   ```
   The badge should appear before the `# 🚀` title line. Look at `.github/workflows/run-demo.yml` for the reference pattern — it uses a HEADER literal heredoc block that starts with the badge.

5. Validate both files:
   - `cd live/demos/combined && terraform init -backend=false && terraform validate`
   - `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/combined-demo.yml'))"`

## Must-Haves

- [ ] VPC resource has `Demo = "true"` and `ManagedBy = "terraform"` tags (case-sensitive match for cleanup filter)
- [ ] IGW resource has `Demo = "true"` and `ManagedBy = "terraform"` tags
- [ ] UDDI badge present in `combined-demo.yml` job summary
- [ ] `terraform validate` passes for `live/demos/combined/`
- [ ] `combined-demo.yml` parses as valid YAML

## Verification

- `grep -c 'ManagedBy' live/demos/combined/main.tf` returns ≥2
- `grep 'Demo.*=.*"true"' live/demos/combined/main.tf` shows matches for VPC and IGW
- `grep -c 'Infoblox-Universal_DDI-0066cc' .github/workflows/combined-demo.yml` returns ≥1
- `grep -c 'Infoblox-Universal_DDI-0066cc' .github/workflows/*.yml` — all 4 files return ≥1
- `cd live/demos/combined && terraform init -backend=false && terraform validate` passes
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/combined-demo.yml'))"` passes

## Inputs

- `live/demos/combined/main.tf` — Created in S01. VPC tags at ~line 60, IGW tags at ~line 73. Currently has lowercase `demo = "true"` but missing `Demo` (uppercase) and `ManagedBy`.
- `.github/workflows/combined-demo.yml` — Created in S01. Has a job summary heredoc but no UDDI badge (0 occurrences vs 1+ in each other workflow).
- Cleanup filter reference: `.github/workflows/cleanup.yml` line 391 uses `--filters "Name=tag:ManagedBy,Values=terraform" "Name=tag:Demo,Values=true"` — these are the exact tag names/values to match.
- Badge format reference: `![Infoblox](https://img.shields.io/badge/Infoblox-Universal_DDI-0066cc)` — exact string from S02 pattern.

## Expected Output

- `live/demos/combined/main.tf` — VPC and IGW resources tagged correctly for cleanup discovery
- `.github/workflows/combined-demo.yml` — UDDI branding badge added to job summary, matching S02's established pattern
