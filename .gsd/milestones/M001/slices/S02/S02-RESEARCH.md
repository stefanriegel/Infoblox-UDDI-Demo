# S02: Narrated Demo Output & Presentation Polish — Research

**Date:** 2026-04-02
**Depth:** Targeted

## Summary

S02 owns R002 (narrated logs), R003 (professional summaries), R004 (consistent branding), R006 (DNS polish), R007 (VPC polish), R008 (timing metrics), R009 (Mermaid diagrams), R011 (cleanup branding). It supports R005 (production-grade feel).

The three target workflows (DNS, VPC, Cleanup) each need different levels of work. The VPC workflow has a **confirmed bug** — its summary job uses single-quoted `echo '${AWS_VERIFICATION}' | jq ...` which prevents bash variable expansion, meaning verification tables always render empty. The DNS workflow is already the most polished but lacks log narration, timing, and has inconsistencies. The cleanup workflow is the simplest — needs branding header, Mermaid, and consistent formatting.

The combined workflow from S01 (`combined-demo.yml`) already implements the target patterns: boxed ASCII headers for phase narration, `date +%s` timing, a Mermaid LR flow diagram, and a clean summary layout. This is the reference implementation to replicate across the other three workflows.

## Recommendation

Use the combined workflow as the gold standard and systematically apply its patterns to all three existing workflows. Work in this order: (1) fix the VPC summary bug first since it's the highest-risk item, (2) establish the shared branding/narration patterns across all workflows, (3) polish each workflow's summary.

Do NOT extract patterns into reusable shell scripts or composite actions — the workflows need to remain self-contained for demo clarity and SE readability. Inline duplication is acceptable; a demo repo is not a DRY codebase.

## Implementation Landscape

### Key Files

- `.github/workflows/run-demo.yml` (1062 lines) — DNS demo. Already has: dynamic Mermaid diagram per provider, shields.io badges, provider-specific verification sections, UDDI API transaction section. Missing: log narration (no step-by-step announcements during terraform init/plan/apply), timing metrics, consistent header branding matching combined workflow style. Summary is functional but verbose — each provider's verification section repeats similar markdown generation. Needs cleanup of the header section to match combined workflow's executive summary format.

- `.github/workflows/vpc-deployment.yml` (633 lines) — VPC demo. **Has confirmed bug in summary job (lines ~540-580):** the `Generate Summary` step sets env vars `AWS_VERIFICATION`, `AZURE_VERIFICATION`, `GCP_VERIFICATION` from job outputs, then uses `echo '${AWS_VERIFICATION}' | jq ...` — single quotes prevent expansion, so jq gets the literal string `${AWS_VERIFICATION}` and fails silently. Fix: change to `echo "${AWS_VERIFICATION}" | jq ...` or use heredoc. Beyond the bug: no Mermaid diagram, no branding badges, no narration in deploy steps, no timing metrics. The deploy loops in `aws_vpcs`/`azure_vnets`/`gcp_vpcs` jobs have basic echo statements but no structured narration.

- `.github/workflows/cleanup.yml` (509 lines) — Cleanup workflow. Two separate summary sections (`Job Summary` in cleanup_dns job, `VPC Cleanup Summary` in cleanup_vpc job). No unified summary, no Mermaid diagram, no branding header, no badges. The summaries are functional but minimal. Needs: unified branding header, a Mermaid diagram showing the cleanup discovery flow, consistent table formatting matching the other workflows.

- `.github/workflows/combined-demo.yml` (417 lines) — **Reference implementation** (from S01). Patterns to replicate:
  - Boxed ASCII narration: `╔══════...╗` / `║  Phase description  ║` / `╚══════...╝`
  - Phase announcements with emoji: `🔷 Phase 1: IPAM — ...`
  - Timing with `date +%s`: capture START_TIME before apply, compute DURATION after
  - Mermaid `graph LR` with phase-colored nodes and consistent `fill:#0066cc` for UDDI
  - Summary with config table + results table + verification table
  - Value proposition footer section
  - Heredoc-based summary generation (cleaner than many `echo >>` lines)

### Presentation Constants (to standardize)

These should be consistent across ALL four workflows:

| Element | Standard |
|---------|----------|
| UDDI brand color | `#0066cc` (Mermaid fill, badges) |
| AWS color | `#FF9900` |
| Azure color | `#0078D4` |
| GCP color | `#4285F4` |
| Cloudflare color | `#f38020` |
| Success color | `#00C853` |
| Verification color | `#7B1FA2` |
| Header badge | `![UDDI](https://img.shields.io/badge/Infoblox-Universal_DDI-0066cc?style=for-the-badge)` |
| Summary title prefix | `# 🚀 Infoblox Universal DDI —` |
| Footer | `**Powered by [Infoblox Universal DDI](...)** \| Terraform UDDI Provider \| GitHub Actions` |

### Build Order

1. **Fix VPC summary bug** — highest risk, fastest to verify. Change single quotes to double quotes for env var expansion in the summary job's jq commands. This is a correctness fix independent of presentation work.

2. **Add narration to DNS workflow** — The DNS workflow has the most complex step structure. Add boxed ASCII headers and phase announcements to: Terraform Init, Terraform Plan, Terraform Apply, DNS Verification steps. Add timing around the apply step. This establishes the narration pattern.

3. **Add narration to VPC workflow** — Similar pattern to DNS but applied to the per-cloud deploy loops (aws_vpcs, azure_vnets, gcp_vpcs jobs). Each deploy loop's inner iterations already have basic echo; enhance them with the boxed header pattern. Add timing per-VPC.

4. **Polish DNS workflow summary** — Refactor the summary steps to use heredoc style (like combined workflow). Standardize the Mermaid diagram styling. Add timing metric to the config table. Add the value proposition footer. Keep the provider-specific verification sections but make them consistent.

5. **Polish VPC workflow summary** — Rewrite the summary job with: branding header + badges, Mermaid diagram showing IPAM→multi-cloud flow, fixed verification tables, timing metrics, value proposition footer. This is the most work since the current summary is bare-bones.

6. **Polish cleanup workflow summary** — Add unified branding header to both summary sections (or merge into one). Add a Mermaid diagram showing the cleanup discovery flow (scan zones → find tagged resources → delete). Add badges and footer.

7. **Add narration to cleanup workflow** — Add phase announcements to the discovery and deletion steps.

### Verification Approach

- **VPC bug fix:** Run `grep -n "echo '\\$" .github/workflows/vpc-deployment.yml` to confirm all single-quoted variable expansions are fixed. Then validate YAML syntax with `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/vpc-deployment.yml'))"`.
- **YAML validity:** After each workflow edit, validate with `python3 -c "import yaml; yaml.safe_load(open('<file>'))"` — catches syntax errors before push.
- **Mermaid rendering:** Mermaid diagrams should be checked by visual inspection of the markdown. Can't fully test without a GitHub Actions run, but syntax can be validated locally.
- **Narration pattern:** Search for the boxed header pattern (`╔══`) in each workflow to confirm narration was added. Verify emoji phase markers (`🔷 Phase`) exist in key steps.
- **Timing pattern:** Search for `date +%s` and `DURATION` in each workflow to confirm timing was added.
- **Branding consistency:** Grep for the standard UDDI badge URL and footer text across all four workflows to confirm consistency.
- **Full validation:** Trigger each workflow via `workflow_dispatch` on GitHub Actions and review the job summary output. This is the ultimate acceptance test but requires cloud credentials.

## Constraints

- **GitHub job summary size limit:** Summaries are markdown appended to `$GITHUB_STEP_SUMMARY`. GitHub renders up to ~1MB but very long summaries may have rendering delays. The DNS workflow is already the longest — avoid making it significantly larger.
- **Multi-job summaries in VPC workflow:** The VPC workflow has 4 jobs (preflight, aws_vpcs, azure_vnets, gcp_vpcs) plus a summary job. Each job gets its own summary section. The summary job aggregates via job outputs — this is where the bug is. The summary job's env vars receive JSON strings from job outputs.
- **Cleanup has two parallel jobs:** `cleanup_dns` and `cleanup_vpc` run independently. Each has its own summary. They can't be merged into one summary without restructuring into a single job or adding a third summary job.
- **Heredoc with GitHub expressions:** Using `cat >> $GITHUB_STEP_SUMMARY << EOF` works but `${{ }}` expressions are expanded by GitHub Actions before bash sees them. This means `${BASH_VAR}` and `${{ inputs.x }}` both work inside unquoted heredocs, but `<< 'EOF'` (quoted) prevents bash expansion while still allowing GitHub expression expansion. The combined workflow uses both patterns — follow its lead.

## Common Pitfalls

- **Single vs double quotes around env vars in summary jobs** — The exact bug in the VPC workflow. When using `echo '${VAR}' | jq`, bash passes the literal `${VAR}` to jq. Always use `echo "${VAR}" | jq` when the variable contains JSON from job outputs. Review ALL summary steps for this pattern.
- **GitHub secret masking in summaries** — GitHub masks any value that matches a secret. The DNS workflow already works around this by using literal zone names (e.g., `echo "| **Zone** | \`virtualife.pro\` |"`) instead of interpolating `${{ steps.set_zone.outputs.zone_fqdn }}`. Continue this pattern — never interpolate values that might match secrets into summary tables.
- **Mermaid syntax strictness** — GitHub's Mermaid renderer is pickier than mermaid.live. Avoid special characters in node labels. Use `<br/>` for line breaks in labels. Always test that the fenced code block uses exactly ` ```mermaid ` with no trailing spaces.
- **YAML multi-line strings** — When adding boxed ASCII art to `run:` blocks, ensure the `|` block scalar is used. The `╔══` characters are UTF-8 safe in YAML but pipe characters inside the art would need escaping if using `>` folded scalars.

## Open Risks

- **Summary rendering differences across GitHub Enterprise vs GitHub.com** — Some customers may view these on GHE which has older Mermaid support. Low risk but worth noting.
- **Timing accuracy** — `date +%s` gives wall-clock seconds. Network latency to cloud APIs adds noise. Timing will vary between runs. The combined workflow shows this already works acceptably — just set expectations in the summary text ("approximately Xs").
