---
estimated_steps: 5
estimated_files: 1
---

# T02: Add narration and polish DNS workflow summary

**Slice:** S02 — Narrated Demo Output & Presentation Polish
**Milestone:** M001

## Description

The DNS demo workflow (`.github/workflows/run-demo.yml`, 1062 lines) is the most-used demo and already has partial polish — a dynamic Mermaid diagram per provider, shields.io badges, and provider-specific verification sections. But it lacks log narration (no step-by-step announcements during terraform operations), timing metrics, and has branding inconsistencies vs the combined workflow standard.

This task adds narration, timing, and harmonizes the branding without changing any Terraform logic or provider-specific verification logic.

Use `.github/workflows/combined-demo.yml` as the **read-only reference** for patterns. Do NOT modify the combined workflow.

**Skills:** Load `github-workflows` skill for GitHub Actions syntax reference.

## Steps

1. **Add boxed ASCII narration to Terraform steps.** Find the key `run:` blocks for terraform init, plan, apply, and DNS verification. Add boxed phase announcements before each:
   ```
   echo "╔══════════════════════════════════════════════════════════════╗"
   echo "║  🔷 Phase N: Description                                    ║"
   echo "╚══════════════════════════════════════════════════════════════╝"
   ```
   Phases: 🔷 Configuration/Setup, 🔷 Terraform Init, 🔷 Terraform Plan, 🔷 Terraform Apply, 🔷 DNS Verification. Adapt to the workflow's step structure — the DNS workflow may have these in different jobs or combined steps.

2. **Add timing around terraform apply.** Capture `START_TIME=$(date +%s)` before the apply command and `END_TIME=$(date +%s)` / `DURATION=$((END_TIME - START_TIME))` after. Pass duration via `$GITHUB_OUTPUT`. Add timing metric to the summary config/results table.

3. **Standardize the summary header.** Ensure the summary starts with:
   - `![UDDI](https://img.shields.io/badge/Infoblox-Universal_DDI-0066cc?style=for-the-badge)` badge
   - `# 🚀 Infoblox Universal DDI — DNS Demo` title
   If existing badges exist, keep them but ensure the UDDI badge is first and uses `0066cc`.

4. **Standardize Mermaid diagram colors.** The DNS workflow already generates dynamic Mermaid based on provider. Update the color fills to use the standard palette: UDDI `fill:#0066cc`, Cloudflare `fill:#f38020`, AWS Route53 `fill:#FF9900`, Azure DNS `fill:#0078D4`, GCP Cloud DNS `fill:#4285F4`, verification `fill:#7B1FA2`, success `fill:#00C853`. If colors are already close, just harmonize.

5. **Add value proposition footer and convert summary sections to heredoc where practical.** Add the standard footer: `**Powered by [Infoblox Universal DDI](https://www.infoblox.com/products/universal-ddi/)** | Terraform UDDI Provider | GitHub Actions`. Where the summary uses many `echo >> $GITHUB_STEP_SUMMARY` lines in sequence, convert to `cat >> $GITHUB_STEP_SUMMARY << EOF` heredoc style for readability. Don't force-convert sections where the current approach works well (e.g., inside conditionals).

## Must-Haves

- [ ] Boxed ASCII narration in key Terraform steps (init, plan, apply, verification)
- [ ] Timing via `date +%s` around terraform apply, duration in summary
- [ ] UDDI branding badge (`Infoblox-Universal_DDI-0066cc`) in summary header
- [ ] Mermaid diagram colors standardized to the palette
- [ ] Value proposition footer present
- [ ] YAML validates without errors
- [ ] No changes to Terraform logic or provider-specific verification logic

## Verification

- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/run-demo.yml'))"` — no errors
- `grep -c '╔══' .github/workflows/run-demo.yml` returns ≥3
- `grep -c 'date +%s' .github/workflows/run-demo.yml` returns ≥1
- `grep -c 'Infoblox-Universal_DDI-0066cc' .github/workflows/run-demo.yml` returns ≥1
- `grep 'Powered by.*Infoblox Universal DDI' .github/workflows/run-demo.yml` returns a match
- `grep '0066cc' .github/workflows/run-demo.yml` returns matches (Mermaid UDDI color)

## Inputs

- `.github/workflows/run-demo.yml` — the target file to modify
- `.github/workflows/combined-demo.yml` — read-only reference for patterns

## Expected Output

- `.github/workflows/run-demo.yml` — polished with narration, timing, standardized branding, harmonized Mermaid colors, and footer
