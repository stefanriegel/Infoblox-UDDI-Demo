---
estimated_steps: 5
estimated_files: 1
---

# T01: Fix VPC bug, add narration and polish VPC workflow summary

**Slice:** S02 — Narrated Demo Output & Presentation Polish
**Milestone:** M001

## Description

The VPC deployment workflow (`.github/workflows/vpc-deployment.yml`, 633 lines) has a confirmed bug and needs full presentation polish. The bug: lines 600, 611, 622 use single-quoted `echo '${VAR}' | jq ...` which prevents bash variable expansion — verification tables always render empty. Beyond the bug, the workflow lacks log narration, Mermaid diagram, timing metrics, and consistent branding.

Use `.github/workflows/combined-demo.yml` as the **read-only reference** for all patterns (boxed ASCII narration, timing, Mermaid style, heredoc summaries, branding). Do NOT modify the combined workflow.

**Skills:** Load `github-workflows` skill for GitHub Actions syntax reference.

## Steps

1. **Fix the env var expansion bug.** In the `summary` job's "Generate Summary" step, find these three lines and change single quotes to double quotes:
   - Line ~600: `echo '${AWS_VERIFICATION}' | jq ...` → `echo "${AWS_VERIFICATION}" | jq ...`
   - Line ~611: `echo '${AZURE_VERIFICATION}' | jq ...` → `echo "${AZURE_VERIFICATION}" | jq ...`
   - Line ~622: `echo '${GCP_VERIFICATION}' | jq ...` → `echo "${GCP_VERIFICATION}" | jq ...`
   Verify no other `echo '${` patterns remain in the file.

2. **Add boxed ASCII narration to deploy jobs.** In `preflight`, `aws_vpcs`, `azure_vnets`, `gcp_vpcs` jobs, add boxed phase announcements before key terraform operations (init, plan, apply). Pattern from combined workflow:
   ```
   echo "╔══════════════════════════════════════════════════════════════╗"
   echo "║  🔷 Phase N: Description                                    ║"
   echo "╚══════════════════════════════════════════════════════════════╝"
   ```
   Add emoji phase markers: 🔷 for IPAM/preflight, 🟠 for AWS, 🔵 for Azure, 🟢 for GCP.

3. **Add timing around terraform apply steps.** In each deploy job's apply step, capture `START_TIME=$(date +%s)` before and `END_TIME=$(date +%s)` / `DURATION=$((END_TIME - START_TIME))` after. Echo the duration and pass it via `$GITHUB_OUTPUT` for the summary.

4. **Rewrite summary job to use heredoc style with full branding.** Replace the current summary generation with:
   - Branding header: `![UDDI](https://img.shields.io/badge/Infoblox-Universal_DDI-0066cc?style=for-the-badge)` badge + `# 🚀 Infoblox Universal DDI — VPC Deployment Demo`
   - Mermaid `graph LR` diagram: UDDI IPAM (fill:#0066cc) → AWS VPCs (fill:#FF9900) + Azure VNets (fill:#0078D4) + GCP VPCs (fill:#4285F4), with success nodes (fill:#00C853)
   - Config table (inputs, market, timing)
   - Per-cloud verification tables (now properly populated after bug fix)
   - Value proposition footer: `**Powered by [Infoblox Universal DDI](https://www.infoblox.com/products/universal-ddi/)** | Terraform UDDI Provider | GitHub Actions`
   Use `cat >> $GITHUB_STEP_SUMMARY << EOF` / `<< 'EOF'` heredoc patterns matching the combined workflow approach.

5. **Validate YAML.** Run `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/vpc-deployment.yml'))"` and fix any syntax errors.

## Must-Haves

- [ ] Single-quoted `echo '${VAR}'` bug fixed on all three lines (600, 611, 622)
- [ ] Boxed ASCII narration present in preflight and all three cloud deploy jobs
- [ ] Timing via `date +%s` around at least one terraform apply per deploy job
- [ ] Mermaid diagram in summary showing IPAM→multi-cloud flow
- [ ] Branding badge and footer matching combined workflow standard
- [ ] Heredoc-based summary generation
- [ ] YAML validates without errors

## Verification

- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/vpc-deployment.yml'))"` — no errors
- `grep -c "echo '\${" .github/workflows/vpc-deployment.yml` returns 0
- `grep -c '╔══' .github/workflows/vpc-deployment.yml` returns ≥3
- `grep -c 'date +%s' .github/workflows/vpc-deployment.yml` returns ≥1
- `grep -c 'Infoblox-Universal_DDI-0066cc' .github/workflows/vpc-deployment.yml` returns ≥1
- `grep '```mermaid' .github/workflows/vpc-deployment.yml` returns a match
- `grep 'Powered by.*Infoblox Universal DDI' .github/workflows/vpc-deployment.yml` returns a match

## Inputs

- `.github/workflows/vpc-deployment.yml` — the target file to modify
- `.github/workflows/combined-demo.yml` — read-only reference for patterns (boxed narration at lines ~78/137/378, timing at ~101-112, Mermaid at ~260-280, heredoc summary at ~256-321, footer at ~321-330)

## Expected Output

- `.github/workflows/vpc-deployment.yml` — fully polished with bug fix, narration, timing, Mermaid, branding, and footer
