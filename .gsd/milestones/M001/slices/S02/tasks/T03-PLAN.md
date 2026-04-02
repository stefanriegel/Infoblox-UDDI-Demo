---
estimated_steps: 5
estimated_files: 1
---

# T03: Add narration and polish cleanup workflow summary

**Slice:** S02 — Narrated Demo Output & Presentation Polish
**Milestone:** M001

## Description

The cleanup workflow (`.github/workflows/cleanup.yml`, 509 lines) has two parallel jobs (`cleanup_dns` and `cleanup_vpc`) each with minimal summaries — no unified branding, no Mermaid diagram, no narration, no badges or footer. This task brings it up to the standard established in the combined workflow and applied to VPC/DNS in T01/T02.

The two-job structure must be preserved (they run in parallel and can't be merged without restructuring). Each job gets its own branding header, and each gets a Mermaid diagram appropriate to its scope.

Use `.github/workflows/combined-demo.yml` as the **read-only reference** for patterns. Also reference the completed T01 (VPC) and T02 (DNS) workflows for consistency — by this point they set the standard.

**Skills:** Load `github-workflows` skill for GitHub Actions syntax reference.

## Steps

1. **Add boxed ASCII narration to discovery and deletion steps.** In `cleanup_dns` job: add phase announcements for zone scanning, record discovery, and record deletion. In `cleanup_vpc` job: add phase announcements for VPC/VNet discovery and deletion per cloud. Pattern:
   ```
   echo "╔══════════════════════════════════════════════════════════════╗"
   echo "║  🧹 Phase N: Description                                    ║"
   echo "╚══════════════════════════════════════════════════════════════╝"
   ```
   Use 🧹 emoji for cleanup phases (thematic).

2. **Add timing around deletion operations.** Capture `START_TIME=$(date +%s)` before and duration after deletion loops. Pass to summary for metrics.

3. **Add branding header to both summary sections.** Each job's summary should start with:
   - `![UDDI](https://img.shields.io/badge/Infoblox-Universal_DDI-0066cc?style=for-the-badge)` badge
   - DNS job: `# 🚀 Infoblox Universal DDI — DNS Cleanup`
   - VPC job: `# 🚀 Infoblox Universal DDI — VPC Cleanup`

4. **Add Mermaid diagrams.** DNS cleanup: `graph LR` showing Scan Zones → Find Tagged Records → Delete Records, with UDDI blue (#0066cc) and provider colors. VPC cleanup: `graph LR` showing Scan Cloud Accounts → Find Tagged VPCs → Delete VPCs per cloud, with appropriate cloud colors. Keep diagrams simple — cleanup flow is straightforward.

5. **Add footer, standardize tables, validate YAML.** Add the standard value proposition footer to both summaries. Ensure any existing tables match the formatting style (aligned columns, backtick-wrapped IDs). Validate: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/cleanup.yml'))"`.

## Must-Haves

- [ ] Boxed ASCII narration in both cleanup_dns and cleanup_vpc jobs
- [ ] Timing via `date +%s` around deletion operations
- [ ] Branding badge in both summary sections
- [ ] Mermaid diagram in both summary sections
- [ ] Value proposition footer in both summaries
- [ ] YAML validates without errors

## Verification

- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/cleanup.yml'))"` — no errors
- `grep -c '╔══' .github/workflows/cleanup.yml` returns ≥2
- `grep -c 'date +%s' .github/workflows/cleanup.yml` returns ≥1
- `grep -c 'Infoblox-Universal_DDI-0066cc' .github/workflows/cleanup.yml` returns ≥1
- `grep '```mermaid' .github/workflows/cleanup.yml` returns a match
- `grep 'Powered by.*Infoblox Universal DDI' .github/workflows/cleanup.yml` returns a match

## Inputs

- `.github/workflows/cleanup.yml` — the target file to modify
- `.github/workflows/combined-demo.yml` — read-only reference for patterns
- `.github/workflows/vpc-deployment.yml` — reference for consistency (completed in T01)
- `.github/workflows/run-demo.yml` — reference for consistency (completed in T02)

## Expected Output

- `.github/workflows/cleanup.yml` — polished with narration, timing, branding, Mermaid diagrams, and footer in both job summaries
