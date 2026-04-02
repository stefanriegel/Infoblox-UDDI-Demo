# S02: Narrated Demo Output & Presentation Polish — UAT

**Milestone:** M001
**Written:** 2026-04-02

## UAT Type

- UAT mode: mixed (artifact-driven for static checks, live-runtime for rendered output)
- Why this mode is sufficient: Presentation changes are verifiable through YAML structure inspection and grep patterns locally, but full confidence requires seeing rendered output in GitHub Actions UI.

## Preconditions

- GitHub Actions enabled on the repository
- Cloud provider credentials configured as repository secrets (AWS, Azure, GCP, Cloudflare, BloxOne)
- Existing DNS zones and IPAM address blocks configured in UDDI (see CLAUDE.md architecture section)
- Workflow dispatch permissions for the tester

## Smoke Test

Trigger the DNS demo workflow via `workflow_dispatch` with defaults (Cloudflare provider, `virtualife.pro` zone). Verify: (1) Actions log shows `╔══` boxed phase banners, (2) job summary has UDDI badge at top and "Powered by Infoblox Universal DDI" footer at bottom, (3) Mermaid diagram renders inline.

## Test Cases

### 1. VPC Bug Fix — Verification Tables Populated

1. Go to Actions → "UDDI-Driven Multi-Cloud VPC Deployment"
2. Trigger with `workflow_dispatch`, select at least AWS
3. Wait for workflow to complete
4. Open the job summary for the `summary` job
5. Scroll to the "AWS Verification" table
6. **Expected:** Table cells contain actual VPC IDs, CIDRs, and states — NOT empty cells or literal `${...}` strings

### 2. VPC Narration in Logs

1. From the same VPC run, open the `aws_vpcs` job log
2. Search for `╔══`
3. **Expected:** Boxed ASCII banners visible before terraform operations, with 🟠 AWS emoji marker. At least 2 banners per cloud job.

### 3. VPC Timing in Summary

1. From the same VPC run, open the job summary
2. Look for timing metrics
3. **Expected:** "AWS deployment completed in Xs" visible in logs. Duration value appears in summary section.

### 4. VPC Mermaid Diagram

1. From the same VPC run, open the job summary
2. Look for the architecture diagram
3. **Expected:** Mermaid `graph LR` renders showing IPAM → AWS/Azure/GCP → Verified flow. UDDI node in blue (#0066cc), cloud nodes in their brand colors.

### 5. VPC No Data Fallback

1. Trigger VPC workflow with only AWS selected (Azure and GCP unchecked)
2. Wait for completion, open job summary
3. **Expected:** AWS section shows real data. Azure and GCP sections show "No data" fallback rows instead of broken/empty tables.

### 6. DNS Narration and Timing

1. Go to Actions → "Infoblox Universal DDI - DNS Demo"
2. Trigger with Cloudflare provider, any record name
3. Open the `deploy` job log
4. **Expected:** 7 boxed `╔══` banners visible — Phase 1 (Config/Zone), Phase 2 (Init), Phase 2b (Validate), Phase 3 (Plan), Phase 4 (Apply), Phase 5 (Verify). Timing line shows "DNS deployment completed in Xs".

### 7. DNS Summary Branding

1. From the same DNS run, open the job summary
2. **Expected:** UDDI badge (`img.shields.io` with `Infoblox-Universal_DDI-0066cc`) at top. Title reads `🚀 Infoblox Universal DDI — DNS Demo`. Footer reads "Powered by Infoblox Universal DDI" with link to `/universal-ddi/`. Config table includes "Apply Duration" row.

### 8. DNS Mermaid Colors

1. From the same DNS summary, inspect the Mermaid diagram
2. **Expected:** Diagram renders with provider-specific colors. UDDI nodes in blue (#0066cc). Verification node present if applicable.

### 9. Cleanup DNS Narration and Summary

1. Go to Actions → Cleanup workflow
2. Trigger with `workflow_dispatch` (action: "destroy")
3. Open the `cleanup_dns` job log
4. **Expected:** Boxed `╔══` banners with 🧹 emoji for Phase 1 (Zone Scanning) and Phase 2 (Record Deletion). Job summary shows UDDI badge, Mermaid diagram (UDDI API → Find Tagged → per-provider fan-out → Delete in red), zones scanned table, and branded footer.

### 10. Cleanup VPC Narration and Summary

1. From the same cleanup run, open the `cleanup_vpc` job log
2. **Expected:** Boxed `╔══` banners for Phase 1 (IPAM Scan), Phases 2-4 (per-cloud cleanup), Phase 5 (UDDI Subnet Deletion). Job summary shows UDDI badge, Mermaid diagram (IPAM Scan → per-cloud Delete → Subnet Release in red), clouds scanned table, and branded footer.

### 11. Cleanup Timing with No Resources

1. Trigger cleanup when no demo resources exist
2. Open job summaries
3. **Expected:** Delete duration shows "N/A" (not an error or missing value) when deletion steps are skipped.

### 12. Cross-Workflow Branding Consistency

1. Trigger DNS, VPC, and Cleanup workflows
2. Compare all three job summaries side by side
3. **Expected:** All three share: (a) same UDDI badge style, (b) same `🚀 Infoblox Universal DDI —` title prefix, (c) same "Powered by Infoblox Universal DDI" footer, (d) consistent table formatting, (e) Mermaid diagrams with the same color palette for shared elements (UDDI always #0066cc).

## Edge Cases

### VPC with all clouds failing

1. Trigger VPC workflow with misconfigured credentials (or when cloud quotas exhausted)
2. **Expected:** Summary job still runs (`if: always()`), renders partial results. Failed clouds show "No data" fallback rows. No crash or empty summary.

### Cleanup with nothing to clean

1. Run cleanup when no demo-tagged resources exist
2. **Expected:** Both jobs complete gracefully. Summaries render with "0 resources found" messaging and "N/A" timing. No errors.

## Failure Signals

- Empty table cells or literal `${VAR}` strings in VPC verification tables → bug regression
- Missing `╔══` banners in any workflow logs → narration not applied
- "Powered by" footer missing from any summary → branding incomplete
- Mermaid block renders as raw text instead of diagram → GitHub rendering issue or syntax error
- "No data" text missing when a cloud is skipped → fallback rows not working
- Summary step crashes → likely heredoc quoting issue (check for unescaped `$` in literal blocks)

## Requirements Proved By This UAT

- R002 — Test cases 2, 6, 9, 10 prove step-by-step narration in all workflows
- R003 — Test cases 7, 9, 10, 12 prove professional summary presentation
- R004 — Test case 12 proves cross-workflow branding consistency
- R006 — Test cases 6, 7, 8 prove DNS presentation polish
- R007 — Test cases 1, 2, 3, 4, 5 prove VPC presentation polish (including bug fix)
- R008 — Test cases 3, 6, 11 prove timing metrics in output
- R009 — Test cases 4, 8, 9, 10 prove Mermaid diagram quality
- R011 — Test cases 9, 10, 11 prove cleanup workflow polish

## Not Proven By This UAT

- R001 (Combined IPAM+DNS workflow) — S01 scope, not S02
- R005 (Production-grade feel) — Partially advanced but primarily S03's responsibility (error handling, SE-friendly inputs)
- R010 (SE-friendly inputs) — S03 scope
- Combined workflow branding consistency — `combined-demo.yml` missing UDDI badge (S03 follow-up)
- Rendering on non-GitHub platforms — Mermaid and badge rendering only verified on GitHub Actions

## Notes for Tester

- The branding badge count is 3/4 (not 4/4) because `combined-demo.yml` was built in S01 before the badge pattern was established. This is a known gap for S03, not a bug.
- Cleanup has two independent summary sections (one per parallel job) — this is intentional, not a layout issue.
- Timing values will vary by run. The test is that they appear and are reasonable (seconds, not negative or zero for actual operations).
- If Mermaid diagrams show as code blocks instead of rendered diagrams, this may be a GitHub UI caching issue — try hard-refreshing the page.
