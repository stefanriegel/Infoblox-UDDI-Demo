# S02 — Narrated Demo Output & Presentation Polish — Research

**Date:** 2026-04-02
**Depth:** Targeted (known technology, multiple files to harmonize)

## Summary

S02's job is to bring all four workflows (DNS, VPC, Cleanup, Combined) to a consistent, professional presentation standard. The DNS workflow (`run-demo.yml`, 1062 lines) is the most polished — it has dynamic Mermaid diagrams, status badges, provider-specific verification sections, and Infoblox branding. The VPC workflow (`vpc-deployment.yml`, 633 lines) has a basic summary with a confirmed bug: env var interpolation uses single quotes, so verification data never renders. The Cleanup workflow (`cleanup.yml`, 509 lines) has a minimal summary with no branding, no Mermaid diagrams, and no timing. The Combined workflow (`combined-demo.yml`, 417 lines) was built during S01 and already has narrated log output, timing, and a Mermaid diagram — but its style doesn't match the DNS workflow's richer pattern.

The work is straightforward: establish a shared presentation pattern (branding header, Mermaid style, narration format, timing approach), apply it to all four workflows, and fix the VPC summary bug. No new technology is involved. The risk is mainly in making the VPC summary job work correctly with cross-job output data.

## Recommendation

Use the DNS workflow's summary as the gold standard — it has the most complete pattern with badges, dynamic Mermaid, config table, verification, value proposition, and footer. Extract a consistent "presentation contract" from it:

1. **Header**: Title with 🚀 emoji, "Executive Summary" paragraph, shields.io badges (Status, Infoblox UDDI, Automation, provider-specific)
2. **Mermaid diagram**: Dynamic based on inputs, Infoblox blue (#0066cc) for UDDI node, provider-specific colors for targets
3. **Configuration table**: Input parameters in a clean table
4. **Results/Verification**: Provider-specific sections with ✅/⏳ status
5. **Value Proposition**: Business benefits section
6. **Footer**: "Powered by Infoblox Universal DDI" with link

Apply this pattern to VPC, Cleanup, and Combined workflows. Add step narration (echo with box-drawing characters and phase announcements) to DNS and Cleanup, which currently lack it. Add `date +%s` timing capture to DNS and VPC workflows that don't have it yet.

## Implementation Landscape

### Key Files

- `.github/workflows/run-demo.yml` — **DNS workflow, gold standard for presentation.** Summary is already rich (lines 690-1063). Needs: step-by-step narration added to Terraform steps (Init/Plan/Apply currently have no echo narration), timing capture around key phases (plan, apply, verification). Summary badge/branding pattern is the template for all others.

- `.github/workflows/vpc-deployment.yml` — **VPC workflow, needs the most work.** Summary job (lines 573-633) has a confirmed bug: lines 600, 611, 622 use `echo '${AWS_VERIFICATION}'` (single quotes) instead of `echo "${AWS_VERIFICATION}"` (double quotes), so env var values are never interpolated — jq receives the literal string `${AWS_VERIFICATION}`. Needs: fix the quote bug, add Infoblox branding header with badges, add Mermaid architecture diagram (UDDI IPAM → multi-cloud VPCs), add narrated echo output to deploy steps, add timing, add value proposition footer.

- `.github/workflows/cleanup.yml` — **Cleanup workflow, minimal summary.** Has two separate summary steps (DNS cleanup at line 192, VPC cleanup at line 448) in separate jobs. Needs: consistent branding, a Mermaid diagram showing the cleanup flow (scan → discover → delete), add narration to the scan/delete steps, consolidate or harmonize the two summary sections.

- `.github/workflows/combined-demo.yml` — **Combined workflow from S01.** Already has narrated output and timing. Needs: align badges and branding header to match DNS workflow style (currently missing shields.io badges), refine Mermaid diagram styling to match DNS diagram conventions, add the "Value Proposition" section formatting to match.

### Build Order

1. **Fix VPC summary bug first** — Single-line fix (single quotes → double quotes on 3 lines), immediately testable. This retires a known risk and proves the cross-job output pipeline works.

2. **Define branding constants and patterns** — Establish the exact badge URLs, Mermaid node colors, section headers, and narration format as a reference. Not a separate file (these are inline in YAML), but documented as a consistent pattern across all workflows.

3. **Polish VPC workflow** — Add full branding header, Mermaid diagram, narration, timing. Biggest transformation since it goes from basic to polished.

4. **Polish Cleanup workflow** — Add branding, Mermaid cleanup-flow diagram, narration to scan/delete steps.

5. **Polish DNS workflow** — Add narration echo to Terraform steps (Init, Plan, Apply) and timing capture. Summary is already good — just add timing metrics.

6. **Align Combined workflow** — Match badge style, refine Mermaid to use consistent node colors and styling.

### Verification Approach

- **VPC bug fix**: Run `bash -n .github/workflows/vpc-deployment.yml` won't catch this (it's valid bash, just wrong). Best verification: search for remaining single-quoted env var refs: `grep "echo '\\${"` across all workflow files. Confirm zero matches post-fix.
- **Presentation consistency**: Visual review of all four summary step blocks. Check that each has: (1) shields.io badges, (2) Mermaid diagram, (3) configuration table, (4) results/verification, (5) value proposition, (6) footer.
- **Narration**: Grep for narration patterns (box-drawing chars `╔`, phase announcements with 🔷/⏳/✅ emojis) in all four workflows.
- **Timing**: Grep for `date +%s` pattern in all four workflows.
- **YAML validity**: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/X.yml'))"` for each file.
- **Final**: Trigger each workflow on GitHub and review the actual job summary output (human verification, matches R003 "visually compelling").

## Constraints

- GitHub Actions job summaries support Mermaid, markdown tables, badges, and `<details>` blocks — but rendering has quirks with very long summaries. Keep each workflow's summary under ~10KB.
- The VPC workflow's summary runs in a separate `summary` job that consumes outputs from parallel cloud jobs. Data passes via `needs.X.outputs.Y` → env vars. This cross-job pattern is fragile — env vars with JSON containing special chars can break.
- shields.io badges are external HTTP requests — they work in GitHub summaries but won't render in offline/air-gapped environments. Acceptable tradeoff for demo use.

## Common Pitfalls

- **VPC cross-job JSON output** — The verification JSON from aws/azure/gcp jobs passes through `$GITHUB_OUTPUT` → `needs.X.outputs.Y` → env var → shell echo → jq. Any step that uses single quotes or fails to properly quote the JSON will silently produce empty output. After fixing the single-quote bug, also check that the env vars are declared at the job level with `${{ needs.X.outputs.Y }}` (they are — lines 577-579 are correct).
- **Heredoc quoting in summaries** — The combined workflow uses `cat >> $GITHUB_STEP_SUMMARY << 'HEADER'` (quoted heredoc, no variable expansion) for static sections and `<< EOF` (unquoted, variables expand) for dynamic sections. This is correct but easy to mix up. VPC and Cleanup may need similar patterns for multi-line summary blocks.
- **GitHub secret masking** — The DNS workflow carefully avoids using zone FQDNs from env vars in summaries (they get masked as secrets). Instead it uses literal strings in case blocks. Any new summary content with zone names should follow this pattern.

## Requirements Coverage

| Requirement | Role | What S02 Delivers |
|-------------|------|-------------------|
| R002 (narration) | Primary owner | Step-by-step echo narration in all 4 workflows |
| R003 (professional summaries) | Primary owner | Consistent, polished job summaries across all 4 workflows |
| R004 (consistent branding) | Primary owner | Shared badge style, Mermaid aesthetics, section headers, footer |
| R006 (DNS polish) | Primary owner | Narration + timing added to DNS workflow |
| R007 (VPC polish) | Primary owner | Bug fix + full presentation overhaul for VPC workflow |
| R008 (timing metrics) | Primary owner | `date +%s` timing around key phases in all workflows |
| R009 (Mermaid diagrams) | Primary owner | Consistent Mermaid style, new diagrams for VPC + Cleanup |
| R011 (cleanup branding) | Primary owner | Branding + summary overhaul for cleanup workflow |
| R005 (production-grade) | Supporting | Professional presentation contributes to production-grade feel |
