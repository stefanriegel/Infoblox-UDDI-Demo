---
id: M001
provides:
  - Combined IPAM+VPC+DNS workflow (combined-demo.yml) — the centerpiece demo showing UDDI's full value in one trigger
  - Professional narrated output with boxed ASCII banners, timing metrics, and Mermaid diagrams in all 4 workflows
  - Consistent Infoblox UDDI branding (badge, title prefix, color palette, footer) across DNS, VPC, Combined, and Cleanup workflows
  - SE-friendly workflow_dispatch inputs with examples, sensible defaults, and zero-config first-demo experience
  - Cross-suite verification script (scripts/verify-s03.sh) with 15 consistency checks
  - VPC workflow bug fix — empty verification tables caused by single-quoted env var expansion
key_decisions:
  - D001: UDDI-native sync only (no dual-write) — the demo story is "create in UDDI, it syncs everywhere"
  - D002: AWS as default combined demo provider — simplest VPC model, SE can choose others
  - D003: Tag-based cleanup with uppercase Demo/ManagedBy tags for discovery
  - D005: Step-by-step narration in logs + professional job summary — logs ARE the demo, summary is the takeaway
  - D006: HEADER/EOF/FOOTER heredoc pattern — literal blocks for static markdown, interpolated for dynamic data
  - D007: Mermaid color palette — UDDI #0066cc, AWS #FF9900, Azure #0078D4, GCP #4285F4, Verification #7B1FA2, Delete #dc3545
patterns_established:
  - Three-phase Terraform config with section comments aligning with workflow narration
  - DNS verification pattern — dig 3 resolvers + cloud API check with ✅/❌ table
  - Heredoc summary pattern — HEADER (literal) + EOF (interpolated) + FOOTER (literal)
  - Boxed ASCII narration (╔══╗) for phase announcements in GitHub Actions logs
  - Cloud-specific emoji markers (🟠 AWS, 🔵 Azure, 🟢 GCP, 🔷 IPAM, 🧹 Cleanup)
  - All AWS demo resources tagged with uppercase Demo/ManagedBy for cleanup discovery
observability_surfaces:
  - GitHub Actions job summaries with Mermaid diagrams, verification tables, and timing metrics
  - Boxed ASCII phase narration in workflow logs (24+ banners across all workflows)
  - scripts/verify-s03.sh — 15-check cross-suite consistency validation
  - Per-resolver DNS verification with expected vs actual values
requirement_outcomes:
  - id: R004
    from_status: active
    to_status: validated
    proof: All 4 workflows contain UDDI badge (grep count 4/4), consistent Mermaid palette, title prefix, and footer. Verified by scripts/verify-s03.sh.
  - id: R010
    from_status: active
    to_status: validated
    proof: All 4 workflows have expanded input descriptions with examples, deploy_aws defaults to true, CIDR explanations added. Verified by scripts/verify-s03.sh assertions.
duration: 125m
verification_result: passed
completed_at: 2026-04-02
---

# M001: Customer Demo Enhancement

**Elevated the Infoblox UDDI demo suite from functional internal tooling to a polished, SE-ready customer demonstration with a new combined IPAM+DNS centerpiece workflow, professional narrated output across all 4 workflows, consistent branding, and zero-friction SE experience.**

## What Happened

Three slices built up the demo suite in layers:

**S01 (Combined IPAM+DNS Workflow)** created the centerpiece demo — a single `workflow_dispatch` trigger that allocates a subnet from UDDI IPAM, provisions an AWS VPC using the allocated CIDR, creates a DNS A record in UDDI pointing to the first usable IP, and verifies DNS propagation against 3 public resolvers plus Route53 API. The Terraform root (`live/demos/combined/`) merges the proven vpc-aws and dns patterns into a three-phase config with 8 variables, 5 resources, and 6 outputs. The workflow has separate deploy and destroy jobs with cached state handoff, phase narration with timing, and a professional job summary with a 3-stage Mermaid diagram.

**S02 (Narrated Demo Output & Presentation Polish)** applied a consistent presentation layer across the three existing workflows. The critical fix was the VPC summary bug — single-quoted heredocs (`echo '${VAR}'`) preventing bash expansion, causing verification tables to always render empty. Beyond the bug fix, all three workflows received boxed ASCII narration banners (24 total), `date +%s` timing around key operations, heredoc-based branded summaries with Mermaid diagrams, and the standardized UDDI badge/title/footer pattern. This slice established the presentation conventions that define the demo suite's visual identity.

**S03 (SE Experience & Final Integration)** was the assembly pass ensuring cross-suite consistency. It fixed the combined demo's resource tags (lowercase `demo` → added uppercase `Demo`/`ManagedBy` for cleanup discovery), added the UDDI badge to `combined-demo.yml` (completing 4/4 coverage), polished all workflow inputs with concrete examples and sensible defaults (deploy_aws now defaults to true for zero-config demos), and created `scripts/verify-s03.sh` — a 15-check verification script that validates YAML parsing, badge presence, tag correctness, Terraform validity, narration coverage, and SE input quality.

## Cross-Slice Verification

**Success Criterion: An SE can trigger the combined IPAM+DNS workflow and walk a customer through the output without verbal explanation**
- ✅ Combined workflow exists with deploy/destroy jobs, phase narration, verification table, and Mermaid diagram. Static verification complete — Terraform validates, YAML parses, all step output references resolve. Live run deferred (requires cloud credentials).

**Success Criterion: All workflows produce consistent, professionally branded job summaries with Mermaid diagrams**
- ✅ All 4 workflows have UDDI badge (4/4), Mermaid diagrams (DNS: 1, VPC: 1, Cleanup: 2, Combined: 1), branded title prefix, and value proposition footer. Heredoc pattern consistent across all.

**Success Criterion: Workflow logs include step-by-step narration with timing that tells the UDDI value story**
- ✅ Boxed ASCII narration in all 4 workflows (DNS: 7, VPC: 8, Cleanup: 9, Combined: 3 banners). Timing via `date +%s` in all 4 (DNS: 2, VPC: 6, Cleanup: 4, Combined: 2 calls).

**Success Criterion: The demo suite never feels like a toy or POC**
- ✅ DNS verification against 3 resolvers + cloud API, tag-based cleanup discovery with uppercase tags, proper error handling with `if:always()` summary jobs, resource lifecycle management. VPC bug fix ensures verification tables actually render.

**Definition of Done verification:**
- ✅ All 3 slices marked `[x]` in roadmap
- ✅ All 3 slice summaries exist (S01: 7.6KB, S02: 10.5KB, S03: 7.8KB)
- ✅ S01→S03 boundary: combined workflow tags match cleanup filters (uppercase Demo/ManagedBy)
- ✅ S02→S03 boundary: combined workflow has UDDI badge matching S02's established pattern
- ✅ Cross-suite verification: `scripts/verify-s03.sh` passes 15/15 checks
- ⏳ Live GitHub Actions run deferred — requires real cloud credentials

## Requirement Changes

- R004 (Consistent branding): active → **validated** — All 4 workflows contain UDDI badge (grep confirms 4/4), consistent Mermaid color palette (D007), title prefix, and branded footer. Verified by scripts/verify-s03.sh.
- R010 (SE-friendly inputs): active → **validated** — All 4 workflows have expanded descriptions with examples, deploy_aws defaults to true for zero-config experience, CIDR explanations added to subnet_size. Verified by scripts/verify-s03.sh assertions.
- R001 (Combined workflow): remains **active** — Static verification complete (Terraform validates, YAML parses, step refs resolve, tags correct). Full validation requires live GitHub Actions run.
- R002 (Log narration): remains **active** — 24+ boxed ASCII banners across all workflows. Full validation requires observing actual log output in a live run.
- R003 (Professional summaries): remains **active** — Heredoc-based summaries with tables, Mermaid, branding in all workflows. Full validation requires GitHub rendering check.
- R005 (Production-grade feel): remains **active** — Cleanup discovery, verification depth, error handling all present. Full validation requires live UAT.
- R006 (DNS polish): remains **active** — Narration, timing, branding complete. Awaits live run.
- R007 (VPC polish): remains **active** — Bug fixed, narration/timing/branding complete. Awaits live run.
- R008 (Timing metrics): remains **active** — Present in all 4 workflows. Awaits live run to see rendered durations.
- R009 (Mermaid diagrams): remains **active** — Present in all 4 workflows with consistent palette. Awaits GitHub rendering check.
- R011 (Cleanup polish): remains **active** — Branded summaries with Mermaid in both parallel jobs. Awaits live run.
- R012 (README/docs): remains **deferred** — Explicitly out of scope for M001.

## Forward Intelligence

### What the next milestone should know
- The demo suite is statically verified and presentation-consistent but has never been run on GitHub Actions since these changes. The first priority should be live runs of all 4 workflows.
- `scripts/verify-s03.sh` is the authoritative consistency check — run it after any workflow or Terraform change.
- The presentation pattern is: UDDI badge → `# 🚀 Infoblox Universal DDI — {Demo Name}` title → Mermaid diagram → config/results tables → value proposition → branded footer, using HEADER/EOF/FOOTER heredoc blocks.
- R012 (README/docs) is the only deferred requirement — the workflows are self-explanatory for now but new SEs need onboarding documentation.

### What's fragile
- **Literal zone name** `aws.gh.blox42.rocks` in combined workflow's Mermaid diagram and summary text — if the zone changes, the summary is wrong even though Terraform uses the variable default correctly.
- **Tag case sensitivity** — cleanup filters on uppercase `Demo`/`ManagedBy` but a future edit could accidentally revert to lowercase and silently break cleanup discovery.
- **YAML `on` key** parses as Python boolean `True` — any Python-based YAML tooling must use `d[True]` not `d['on']`.
- **Heredoc quoting** — HEADER/FOOTER are literal (no expansion), EOF is interpolated. Mixing these up silently breaks variable expansion (the exact VPC bug that S02/T01 fixed).
- **`replace(trimspace(results[0]))` CIDR parsing** — if the BloxOne IPAM provider changes output format, both vpc-aws and combined demos break simultaneously.

### Authoritative diagnostics
- `bash scripts/verify-s03.sh` — single command for 15-check cross-suite consistency validation
- `cd live/demos/combined && terraform validate` — confirms Terraform config integrity
- `grep -c 'Infoblox-Universal_DDI' .github/workflows/*.yml` — quick badge coverage check (expect 5+ across 4 files)
- `grep -c "echo '\${" .github/workflows/vpc-deployment.yml` returning 0 confirms VPC bug is fixed

### What assumptions changed
- Plan assumed `aws_subnet` resource existed in combined demo — it doesn't (only `bloxone_ipam_subnet`), so only VPC and IGW needed cleanup tags.
- Plan assumed DNS Mermaid needed color standardization — it was already correct.
- Plan expected branding badge in combined-demo.yml from S01 — S01 was built before S02 established the badge pattern, so S03 had to add it.

## Files Created/Modified

- `live/demos/combined/main.tf` — Three-phase Terraform config (IPAM → VPC → DNS) with providers, resources, outputs, and cleanup tags
- `live/demos/combined/variables.tf` — 8 variable definitions with types, defaults, descriptions, and validation blocks
- `.github/workflows/combined-demo.yml` — Combined workflow with deploy/destroy jobs, narration, DNS verification, Mermaid summary, UDDI badge
- `.github/workflows/run-demo.yml` — DNS workflow with narration, timing, branding header, heredoc value proposition, footer, expanded input descriptions
- `.github/workflows/vpc-deployment.yml` — VPC workflow with bug fix, narration, timing, Mermaid, branding, SE-friendly defaults (deploy_aws=true)
- `.github/workflows/cleanup.yml` — Cleanup workflow with narration, timing, branded summaries with Mermaid in both parallel jobs
- `scripts/verify-s03.sh` — 15-check cross-suite verification script
